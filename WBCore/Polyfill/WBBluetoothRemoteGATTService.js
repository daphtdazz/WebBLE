/*jslint
        browser
*/
/*global
        Event, nslog, uk, window
*/
//  Copyright 2020 David Park. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// adapted from chrome app polyfill https://github.com/WebBluetoothCG/chrome-app-polyfill

(function () {
  'use strict';

  const wb = uk.co.greenparksoftware.wb;
  const wbutils = uk.co.greenparksoftware.wbutils;

  function BluetoothRemoteGATTService(device, uuid, isPrimary) {
    if (device === undefined || uuid === undefined || isPrimary === undefined) {
      throw new Error('Invalid call to BluetoothRemoteGATTService constructor');
    }
    wbutils.defineROProperties(this, {
      device: device,
      uuid: uuid,
      isPrimary: isPrimary
    });
  }

  BluetoothRemoteGATTService.prototype = {
    getCharacteristic: function (uuid) {
      let canonicalUUID = window.BluetoothUUID.getCharacteristic(uuid);
      let service = this;
      return this.sendMessage(
        'getCharacteristic',
        {data: {characteristicUUID: canonicalUUID}}
      ).then(function (CharacteristicJSON) {
        nslog(`Got characteristic ${uuid}`);
        return new wb.BluetoothRemoteGATTCharacteristic(
          service,
          canonicalUUID,
          CharacteristicJSON.properties
        );
      });
    },
    getCharacteristics: function () {
    let service = this;
     return this.sendMessage(
       'getCharacteristics'
     ).then(function (characteristicsForServiceJSON) {
            let characteristics = [];

            if (characteristicsForServiceJSON) {
                for (let i = 0; i < characteristicsForServiceJSON.length; i++) {
                    let characeristicUUID = characteristicsForServiceJSON[i];
                    if (characeristicUUID) {
                        let canonicalUUID = window.BluetoothUUID.getCharacteristic(characeristicUUID);
                        characteristics.push(new wb.BluetoothRemoteGATTCharacteristic(
                          service,
                          canonicalUUID
                        ));
                    }
                }
            }

            return characteristics;
     });
    },
    getIncludedService: function () {
      throw new Error('Not implemented');
    },
    getIncludedServices: function () {
      throw new Error('Not implemented');
    },
    sendMessage: function (type, messageParms) {
      messageParms = messageParms || {};
      messageParms.data = messageParms.data || {};
      messageParms.data.serviceUUID = this.uuid;
      return this.device.gatt.sendMessage(type, messageParms);
    },
    toString: function () {
      return `BluetoothRemoteGATTService(${this.device}, ${this.uuid}, ${this.isPrimary})`;
    }
  };
  wb.BluetoothRemoteGATTService = BluetoothRemoteGATTService;
})();
