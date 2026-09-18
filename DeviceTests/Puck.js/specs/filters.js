// Added in 1.1.4
describe('Filters-1.1.4', function () {
    "use strict";

    it('should allow no name or namePrefix', function (complete) {
        let next_step_h3 = document.getElementById('next-action');

        let options = {filters: [{services: [NORDIC_SERVICE]}]};

        next_step_h3.innerHTML = 'name / namePrefix not required: Pick a NORDIC_SERVICE device...';
        navigator.bluetooth.requestDevice(options).then(function (dev) {
            expect(dev).toBeDefined();
            next_step_h3.innerHTML = 'Done';
        }).catch(function (err) {
            expect(err).toBeUndefined();
            next_step_h3.innerHTML = 'Done';
        }).then(complete);
    }, 20000);
});

// Added in 1.1.6
describe('Filters-1.1.6', function () {
    "use strict";
    const longString = (
        'this is a very long string more than 248 characters really it is i think it is a' +
        'this is a very long string more than 248 characters really it is i think it is a' +
        'this is a very long string more than 248 characters really it is i think it is a' +
        '123456789'
    );

    let next_step_h3;

    beforeEach(() => {
        next_step_h3 = document.getElementById('next-action');
        next_step_h3.innerHTML = '';
    });

    it('should not allow long name', function (complete) {
        navigator.bluetooth.requestDevice({ filters: [{ name: longString }] }).then(
            res => expect('path').toEqual('invalid'),
        ).catch(exc => expect(`${exc}`).toMatch(/Invalid filter name/)).then(complete);
    });

    it('should not allow long namePrefix', function (complete) {
        navigator.bluetooth.requestDevice({ filters: [{ namePrefix: longString }] }).then(
            res => expect('path').toEqual('invalid'),
        ).catch(exc => expect(`${exc}`).toMatch(/Invalid filter namePrefix/)).then(complete);
    });

    it('should allow a name prefix which is Puck', function (complete) {
        navigator.bluetooth.requestDevice({ filters: [{ namePrefix: 'Puck' }] }).then(
            dev => expect(dev).toBeDefined(),
        ).catch(exc => expect(exc).not.toBeDefined()).then(complete);
    }, 20000);

    it('should not find anything with a random name prefix which is Puck', function (complete) {
        next_step_h3.innerHTML = 'Power up a puck, but you should not see it appear as it is not' +
        'filtered in, so cancel';
        navigator.bluetooth.requestDevice({ filters: [{ namePrefix: 'gobblededook' }] }).then(
            dev => expect(dev).toBeDefined(),
        ).catch(exc => expect(`${exc}`).toMatch(/User cancelled/)).then(complete);
    }, 20000);
});
