/*jslint
        browser
*/
/*global
        Event, uk, window
*/
eval('var uk = uk || {};');
if (!uk.co) {
  uk.co = {};
}
if (!uk.co.greenparksoftware) {
  uk.co.greenparksoftware = {};
}
uk.co.greenparksoftware.wb = {};
(function () {
  const wbutils = uk.co.greenparksoftware.wbutils = {
    utf8ByteLen: function (string) {
      return new TextEncoder().encode(string).byteLength;
    },
    btDeviceNameIsOk: function (name) {
      'use strict';
      let nameUTF8len = wbutils.utf8ByteLen(name);
      return nameUTF8len <= 248 && nameUTF8len >= 0;
    },
    canonicaliseFilter: function (filter) {
      'use strict';
      // implemented as far as possible as per
      // https://webbluetoothcg.github.io/web-bluetooth/#bluetoothlescanfilterinit-canonicalizing
      const services = filter.services;
      const name = filter.name;
      if (name !== undefined && !wbutils.btDeviceNameIsOk(name)) {
        throw new TypeError(`Invalid filter name ${name}`);
      }
      const namePrefix = filter.namePrefix;
      if (namePrefix !== undefined && !wbutils.btDeviceNameIsOk(namePrefix)) {
        throw new TypeError(`Invalid filter namePrefix ${namePrefix}`);
      }

      let canonicalizedFilter = { name, namePrefix };

      if (services === undefined && name === undefined && namePrefix === undefined) {
        throw new TypeError('Filter has no usable properties');
      }
      if (services !== undefined) {
        if (!services) {
          throw new TypeError('Filter has empty services');
        }
        let cservs = services.map(window.BluetoothUUID.getService);
        canonicalizedFilter.services = cservs;
      }

      return canonicalizedFilter;
    },
    defineROProperties: function (target, roDescriptors) {
      Object.keys(roDescriptors).forEach(function (key) {
        Object.defineProperty(target, key, {value: roDescriptors[key]});
      });
    },
    mixin: function (target, src) {
      Object.assign(target.prototype, src.prototype);
      target.prototype.constructor = target;
    }
  };

  let levelHandlers = {
    log: console.log,
    warn: console.warn,
    error: console.error,
  };
  function consoleLog(level, message, ...args) {
    window.webkit.messageHandlers.logger.postMessage({level, message: `${message}`});
    if (levelHandlers[level]) {
        levelHandlers[level].call(window.console, message, ...args);
    }
  }
  window.console = {
    debug: (...args) => consoleLog('debug', ...args),
    info: (...args) => consoleLog('log', ...args),
    log: (...args) => consoleLog('log', ...args),
    warn: (...args) => consoleLog('warn', ...args),
    error: (...args) => consoleLog('error', ...args),
    dir: (...args) => consoleLog('log', ...args),
  };
  window.addEventListener('error', function (event) {
    consoleLog('error', `Uncaught error on ${event.filename || "<no filename>"}:${event.lineno || "<no lineno>"} – "${event.message}" ${event.error}`);
  });
})();

(function () {
  function nslog(message) {
    // nslog is called in the various JS polyfills
    // console.log(message);
  }
  window.nslog = nslog;
})();
window.nslog('WBUtils imported');
