describe('writeValue', function () {
  "use strict";

  afterEach(async function () {
    await tidyPuckForTesting();
  });

  it('oversized array buffer should not break the bluetooth connection', async function () {
    const { rxChar, txChar, puck, waitFor } = await getPuckForTesting();

    const message = 'print("bigbuf");\n';

    // 32 meg should do it
    let buffer = new ArrayBuffer(3200000);
    let view8 = new Uint8Array(buffer, 10000, message.length);
    for (let ii = 0; ii < message.length; ii += 1) {
      view8[ii] = message.charCodeAt(ii);
    }

    txChar.writeValue(view8);
    await waitFor('bigbuf');

    puck.gatt.disconnect();
  }, 30000);

  it('should support u16 array', async function () {
    const { rxChar, txChar, puck, waitFor } = await getPuckForTesting();

    // Check we can cast something as U16 and pass it in and it still works. Byte-order is
    // platform specific but that won't matter as we don't actually change the underlying data
    // by using a U16 wrapper.

    const message = 'print("from u16 array 😉");       \n';
    console.log("writing message: " + message);
    await txChar.writeValue(new Uint16Array(str2ab(message)));
    await waitFor('😉');

    puck.gatt.disconnect();
  }, 30000);

  it("should throw if invalid type passed to it", async function () {
    const { txChar } = await getPuckForTesting();

    for (let think of [undefined, null, 1234, [123, 1234, 4321]]) {
      try {
        await txChar.writeValue(think)
      } catch (e) {
        expect(`${e}`).toMatch('TypeError: Invalid argument');
      }
    }
  });
});
