const {
  clearCachedPucks,
  getPuckForTesting,
  tidyPuckForTesting,
} = (() => {

  let reusablePucks = [];
  let inUsePucks = [];

  async function getPuckForTesting(msg) {
    let puck;
    if (reusablePucks.length > 0) {
      puck = reusablePucks.shift();
      console.log(`Got existing puck to use ${puck}`);
      inUsePucks.push(puck)
      setNextAction(
        `Attempting to reconnect to puck #${inUsePucks.length} (ensure it has a battery in...)`
      );
      await puck.gatt.connect();
      console.log("connected")
      setNextAction("...");
    } else {
      puck = await getConnectedPuck(msg || `Select puck #${inUsePucks.length + 1}`);
      inUsePucks.push(puck);
    }
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

  function tidyPuckForTesting() {
    while (inUsePucks.length > 0) {
      let puck = inUsePucks.pop();
      puck.gatt.disconnect();
      reusablePucks.splice(0, 0, puck);
      console.log("Released puck back");
    }
    setNextAction("done test");
  }

  function clearCachedPucks() {
    inUsePucks = [];
    reusablePucks = [];
  }

  return { clearCachedPucks, getPuckForTesting, tidyPuckForTesting };
})();
