/*global
        atob, Event, nslog, uk, window
*/
// https://webbluetoothcg.github.io/web-bluetooth/ interface
(function () {
  'use strict';

  const wb = uk.co.greenparksoftware.wb;
  const wbutils = uk.co.greenparksoftware.wbutils;

  wb.BluetoothRemoteGATTServer = function (webBluetoothDevice) {
    if (webBluetoothDevice === undefined) {
      throw new Error('Attempt to create BluetoothRemoteGATTServer with no device');
    }
    wbutils.defineROProperties(this, {device: webBluetoothDevice});
    this.connected = false;
  };
  wb.BluetoothRemoteGATTServer.prototype = {
    connect: async function () {
      await this.sendMessage('connectGATT');
      this.connected = true;
      wb.native.registerDeviceForNotifications(this.device);
      return this;
    },
    disconnect: function () {
      if (!this.connected) {
        nslog("Unexpected disconnect when gattserver not connected on device ${this.device.id}");
        return;
      }
      this.connected = false;

      // since we've set connected false this event won't be generated
      // by the shortly to be dispatched disconnect event.
      this.device.dispatchEvent(new wb.BluetoothEvent('gattserverdisconnected', this.device));
      wb.native.unregisterDeviceForNotifications(this.device);
      // If there were two devices pointing at the same underlying device
      // this would break both connections, so not really what we want,
      // but leave it like this till someone complains.
      this.sendMessage('disconnectGATT');
    },
    getPrimaryService: async function (uuid) {
      if (!uuid) {
        return Promise.reject(new Error('getPrimaryService requires a UUID'));
      }
      const services = await this.getPrimaryServices(uuid);
      return services[0];
    },
    getPrimaryServices: async function (uuid) {
      const data = {
      data: uuid ? {serviceUUID: window.BluetoothUUID.getService(uuid)} : {},
      };
      const serviceUUIDs = await this.sendMessage('getPrimaryServices', data);
      return serviceUUIDs.map(uuidInner => new wb.BluetoothRemoteGATTService(
        this.device,
        window.BluetoothUUID.getService(uuidInner),
        true,
      ));
    },
    sendMessage: async function (type, messageParms) {
      messageParms = messageParms || {};
      messageParms.data = messageParms.data || {};
      messageParms.data.deviceId = this.device.id;
      return await wb.native.sendMessage('device:' + type, messageParms);
    },
    toString: function () {
      return `BluetoothRemoteGATTServer(${this.device.toString()})`;
    },
  };
})();
