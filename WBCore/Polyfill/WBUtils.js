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
    getBestIconURL: function () {
      var links = document.querySelectorAll(
        ["link[rel~='icon']", "link[rel~='apple-touch-icon']"]
      );

      let bestLink = null;
      let bestIsAppleTouch = false;
      let lastRes = null;

      for (const link of links) {
        if (!link.href) {
          continue;
        }

        const isAppleTouch = link.rel === 'apple-touch-icon';
        if (bestIsAppleTouch && !isAppleTouch) {
          continue;
        }

        // If resolution is not specified assume it's the worst.
        let res = 0;
        if (link.sizes) {
          let match = link.sizes.toString().match(/(\d+)x(\d+)/);

          if (match) {
            let parsedRes = parseInt(match[1]);
            if (!isNaN(parsedRes)) {
              res = parsedRes;
            }
          }
        }
        if (
          isAppleTouch === bestIsAppleTouch
          && lastRes !== null
          && lastRes > res
        ) {
          continue;
        }

        bestLink = link;
        bestIsAppleTouch = isAppleTouch;
        lastRes = res;
      }
      return bestLink && bestLink.href;
    },
    mixin: function (target, src) {
      Object.assign(target.prototype, src.prototype);
      target.prototype.constructor = target;
    },
    uint8ViewOn: function(viewOrBuffer) {
      // value may be an ArrayBuffer or a TypedArray (view onto an ArrayBuffer). We want to extract
      // the bytes into an array so we can send it as a natively supported data type to swift.
      if (viewOrBuffer === undefined || viewOrBuffer === null) {
        throw new TypeError("Invalid argument to writeValue: ${viewOrBuffer}");
      }
      let shared_buffer_type;
      try {
        shared_buffer_type = SharedArrayBuffer;
      } catch {
        shared_buffer_type = ArrayBuffer;
      }

      if (viewOrBuffer instanceof ArrayBuffer || viewOrBuffer instanceof shared_buffer_type) {
        return new Uint8Array(viewOrBuffer);
      }
      const buffer = viewOrBuffer.buffer;
      if (ArrayBuffer.isView(viewOrBuffer)) {
        return new Uint8Array(buffer, viewOrBuffer.byteOffset, viewOrBuffer.byteLength);
      }

      try {
        const typeName = Object.getPrototypeOf(viewOrBuffer).constructor.name
        throw new TypeError(`Invalid argument to writeValue, type: ${typeName}`);
      } catch {}
      throw new TypeError(`Invalid argument to writeValue, type: ${viewOrBuffer}`);
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
