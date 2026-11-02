/*global
    Puck, uk, window, describe, fit, it, expect, str2ab, NORDIC_SERVICE, navigator
*/
/*jslint es6
*/

describe('Device', function () {
    "use strict";

    afterEach(tidyPuckForTesting);

    function setNextAction(action) {
        let stepH3 = document.getElementById('next-action');
        stepH3.innerHTML = action;
    }
    function clearNextAction() {
        setNextAction('');
    }

    beforeEach(() => {
        clearNextAction();
    });

    it('should allow reconnect', async function () {
        let { puck } = await getPuckForTesting();

        const gattServer = puck.gatt;

        var disconnectedAction;
        let disconnectedPromise = new Promise((resolve, reject) => {
            disconnectedAction = resolve;
        });

        puck.addEventListener('gattserverdisconnected', function() {
            console.log("server disconnected");
            disconnectedAction();
        });

        setNextAction("Remove the battery from the puck to cause a disconnection");

        await disconnectedPromise;
        expect(puck.gatt.connected).toBeFalsy();

        clearNextAction();

        // Attempt to reconnect
        expect(gattServer).toEqual(puck.gatt);
        setNextAction("Replace the battery to reconnect");
        await puck.gatt.connect();
        expect(puck.gatt.connected).toBeTruthy();

        // TO BE IMPLEMENTED
        // show we can now get the device use getDevices
        // let devs = await navigator.bluetooth.getDevices();

        // expect(devs.map(d => d.id)).toContain(dev.id);

        // await dev.forget();

        // devs = await navigator.bluetooth.getDevices();
        // expect(devs.map(d => d.id)).not.toContain(dev.id);
    }, 30000);

    it('should allow auto-reconnect after navigating away and back', async function() {
        let { puck } = await getPuckForTesting();

        let resolveDisconnected;
        let disconnectedPromise = new Promise(resolve => {
            resolveDisconnected = resolve;
        });
        puck.addEventListener('gattserverdisconnected', () => {
            console.log("gattserverdisconnected")
            resolveDisconnected();
        });

        setNextAction("Navigate somewhere else and come back to continue");

        await disconnectedPromise;

        setNextAction("...");
        expect(puck.gatt.connected).toBeFalsy();
        await puck.gatt.connect();
        console.log("reconnected");
        expect(puck.gatt.connected).toBeTruthy();
    }, 30000);

    it('requesting same device again should have the same ID', async function() {
        let { puck } = await getPuckForTesting();
        let firstPuckId = puck.id;

        puck.gatt.disconnect();
        tidyPuckForTesting();
        clearCachedPucks();
        setNextAction("re-select the same device to confirm the ID doesn't change");

        console.log("getting next puck")
        let { puck: puck2 } = await getPuckForTesting();
        expect(puck2.id).toEqual(firstPuckId);

    }, 30000);

});
