/*global
    Puck, uk, window, describe, fit, it, expect, str2ab, NORDIC_SERVICE, navigator
*/
/*jslint es6
*/
describe('Filters-1.3.0', function () {
    "use strict";

    beforeEach(() => {
        clearNextAction();
    });

    it('should resolve a short UUID', function () {
        expect(BluetoothUUID.canonicalUUID(0xFFE0)).toEqual('0000ffe0-0000-1000-8000-00805f9b34fb');
    });

    it('should find a puck when filtering by service and name prefix separately', function (complete) {
        setNextAction('Select a Puck (filtered by namePrefix: "Puck.js" and NORDIC_SERVICE separately)');
        navigator.bluetooth.requestDevice({ filters: [
            {services: [NORDIC_SERVICE]},
            {namePrefix: 'Puck.js'},
        ] }).then(
            dev => expect('dev').toBeDefined(),
        ).catch(exc => expect(`${exc}`).not.toBeDefined()).then(complete);
    });

    it('should find a puck when filtering by service and name prefix together', function (complete) {
        setNextAction('Select a Puck (filtered by namePrefix: "Puck.js" and NORDIC_SERVICE together)');
        navigator.bluetooth.requestDevice({ filters: [
            {
                services: [NORDIC_SERVICE],
                namePrefix: 'Puck.js',
            },
        ] }).then(
            dev => {
                console.log(`name of puck: ${dev.name}`);
                expect('dev').toBeDefined();
            },
        ).catch(exc => expect(`${exc}`).not.toBeDefined()).then(complete);
    });

    it('should find a puck when filtering by service and name together', function (complete) {
        setNextAction('Select a Puck');
        navigator.bluetooth.requestDevice({ filters: [
            {
                services: [NORDIC_SERVICE],
            },
            {
                name: 'Puck.js c933',
            },
        ] }).then(
            dev => expect('dev').toBeDefined(),
        ).catch(exc => expect(`${exc}`).not.toBeDefined()).then(complete);
    });
});
