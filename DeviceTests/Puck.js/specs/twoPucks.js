/*global
    Puck, uk, window, describe, it, expect, str2ab
*/
/*jslint es6
*/

describe('2 Pucks', function () {
    "use strict";
    afterEach(tidyPuckForTesting);

    it('should be independent, connectable, readable, and disconnectable', async function () {
        let charPromiseResolve = {};
        let deviceBuffers = {};

        function charNotification(event) {
            let did = event.target.service.device.id;
            if (deviceBuffers[did] === undefined) {
                deviceBuffers[did] = '';
            }
            deviceBuffers[did] += ab2str(event.target.value.buffer);
        }

        async function deviceBufferMatches(did, match) {
            const start = Date.now();
            return new Promise((resolve, reject) => {
                const tid = setInterval(() => {
                    if ((deviceBuffers[did] || '').search(match) !== -1) {
                        console.log(`Matched ${match}`);
                        deviceBuffers[did] = '';
                        clearInterval(tid);
                        resolve();
                        return;
                    }

                    const now = Date.now();
                    if (start + 2000 < now) {
                        console.log(`Timeout waiting for ${match} (buffer ${deviceBuffers[did]})`);
                        clearInterval(tid);
                        reject('Timeout');
                        return;
                    }
                }, 1);
            });
        }

        let { puck: puck1 } = await getPuckForTesting('Pick a first puck');
        let { puck: puck2 } = await getPuckForTesting('Pick a second puck');

        const devs = [puck1, puck2];
        expect(devs.every(d => d !== undefined)).toBeTruthy();
        expect(devs[0].id).not.toBe(devs[1].id);

        async function resetCheckDevice(device) {
            const service = await device.gatt.getPrimaryService(NORDIC_SERVICE);
            const [rxChar, txChar] = await Promise.all([
                service.getCharacteristic(NORDIC_RX),
                service.getCharacteristic(NORDIC_TX),
            ]);
            expect(rxChar).toBeDefined();
            expect(txChar).toBeDefined();

            rxChar.addEventListener('characteristicvaluechanged', charNotification);

            await rxChar.startNotifications();
            await txChar.writeValue(str2ab("echo(true);\n"));
            await deviceBufferMatches(device.id, '\n>$');
            await txChar.writeValue(str2ab("reset();\n"));
            await deviceBufferMatches(device.id, '\n>$');
            await txChar.writeValue(str2ab("echo(false);\n"));
            await txChar.writeValue(str2ab("print('echoing');\n"));
            await deviceBufferMatches(device.id, 'echoing');

            device.rxChar = rxChar;
            device.txChar = txChar;
        }

        console.log(`await resets and initial echoes`);
        await Promise.all(devs.map(resetCheckDevice));

        // OK, so now we ask them both to print hello.
        console.log(`await hellos`);
        await Promise.all(devs.map((dev, ind) => Promise.all([
            dev.txChar.writeValue(str2ab(`print('${ind}');\n`)),
            deviceBufferMatches(dev.id, `${ind}`),
        ])));

        setNextAction('Disconnect both pucks (e.g. remove the battery).');
        await Promise.all(devs.map(dev => new Promise(resolve => dev.addEventListener(
            'gattserverdisconnected',
            (ev) => {
                expect(ev.target).toBe(dev);
                resolve();
            },
        ))));
    }, 60000);
});
