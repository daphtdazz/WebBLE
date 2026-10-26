describe('getPrimaryServices', function () {
  "use strict";
  afterAll(clearNextAction);
  afterEach(tidyPuckForTesting);

  it('should return some primary services', async () => {
    const puck = await getConnectedPuck('Select a puck (so we can get primary services)');
    expect(puck).toBeDefined();

    const servs = await puck.gatt.getPrimaryServices();

    // only really expecting one but for future compatibility...
    expect(servs.length).toBeGreaterThan(0);
    const serv = servs.find(s => s.uuid === NORDIC_SERVICE);
    expect(serv).toBeDefined();

    puck.gatt.disconnect();
  }, 60000);
});
