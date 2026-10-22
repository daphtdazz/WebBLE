const {
  getPuckForTesting,
  tidyPuckForTesting,
} = (() => {

  let puck;

  async function getPuckForTesting() {

    puck = await getConnectedPuck('Select a puck');
    const service = await puck.gatt.getPrimaryService(NORDIC_SERVICE);
    const [rxChar, txChar] = await Promise.all([
      service.getCharacteristic(NORDIC_RX),
      service.getCharacteristic(NORDIC_TX),
    ]);

    let output = '';
    let waiter;
    function charNotification(event) {
      console
      output += ab2str(event.target.value.buffer);
      if (waiter) {
        waiter();
      }
    }

    async function waitFor(match) {
      return new Promise((resolve) => {
        waiter = () => {
          if (output.search(match) !== -1) {
            expect(`Got match ${match}`).toBeTruthy();
            waiter = undefined;
            output = '';
            resolve();
          }
        };
      });
    }

    rxChar.addEventListener('characteristicvaluechanged', charNotification);
    await rxChar.startNotifications();

    // check we're echoing
    await txChar.writeValue(str2ab('echo(true);\n'));
    await waitFor('\n>$');

    return { txChar, puck, waitFor };
  }

  async function tidyPuckForTesting() {
    puck.gatt.disconnect()
  }

  return { getPuckForTesting, tidyPuckForTesting };
})();
