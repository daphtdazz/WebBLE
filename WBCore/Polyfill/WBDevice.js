/*global
        Event, nslog, uk, window
*/
// https://webbluetoothcg.github.io/web-bluetooth/ interface

(function () {
  'use strict';

  const wb = uk.co.greenparksoftware.wb;
  const wbutils = uk.co.greenparksoftware.wbutils;

  // https://webbluetoothcg.github.io/web-bluetooth/ interface
  nslog('Create BluetoothDevice');
  wb.BluetoothDevice = function (deviceJSON) {
    wbutils.EventTarget.call(this);

    let roProps = {
      adData: {},
      deviceClass: deviceJSON.deviceClass || 0,
      id: deviceJSON.id,
      gatt: new wb.BluetoothRemoteGATTServer(this),
      productId: deviceJSON.productId || 0,
      productVersion: deviceJSON.productVersion || 0,
      uuids: deviceJSON.uuids,
      vendorId: deviceJSON.vendorId || 0,
      vendorIdSource: deviceJSON.vendorIdSource || 'bluetooth'
    };
    wbutils.defineROProperties(this, roProps);

    this.name = deviceJSON.name;

    if (deviceJSON.adData) {
      this.adData.appearance = deviceJSON.adData.appearance || '';
      this.adData.txPower = deviceJSON.adData.txPower || 0;
      this.adData.rssi = deviceJSON.adData.rssi || 0;
      this.adData.manufacturerData = deviceJSON.adData.manufacturerData || [];
      this.adData.serviceData = deviceJSON.adData.serviceData || [];
    }
  };

  wb.BluetoothDevice.prototype = {
    toString: function () {
      return `BluetoothDevice(${this.id.slice(0, 10)})`;
    },
    handleSpontaneousDisconnectEvent: function () {
      // Code references as per
      // https://webbluetoothcg.github.io/web-bluetooth/#disconnection-events
      // 1. not implemented
      // 2.
      if (!this.gatt.connected) {
        return;
      }
      // 3.1
      this.gatt.connected = false;
      // 3.2-3.7 not implemented
      // 3.8
      this.dispatchEvent(new wb.BluetoothEvent('gattserverdisconnected', this));
    }
  };
  wbutils.mixin(wb.BluetoothDevice, wbutils.EventTarget);
})();
