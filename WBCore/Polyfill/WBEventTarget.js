/*jslint
    browser
*/
/*global
    Event, uk, window
*/
//
// We need an EventTarget implementation. This one nicked wholesale from
// https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
//
(function () {
  'use strict';
  const wbutils = uk.co.greenparksoftware.wbutils;

  window.nslog('Build EventTarget');
  wbutils.EventTarget = function () {
    this.listeners = {};
  };

  wbutils.EventTarget.prototype = {
    addEventListener: function (type, callback) {
      if (this.listeners[type] === undefined) {
        this.listeners[type] = [];
      }
      this.listeners[type].push(callback);
    },
    removeEventListener: function (type, callback) {
      let stack = this.listeners[type];
      if (stack === undefined) {
        return;
      }
      let l = stack.length;
      let ii;
      for (ii = 0; ii < l; ii += 1) {
        if (stack[ii] === callback) {
          stack.splice(ii, 1);
          return this.removeEventListener(type, callback);
        }
      }
    },
    dispatchEvent: function (event) {
      let stack = this.listeners[event.type];
      if (stack === undefined) {
        return;
      }
      event.currentTarget = this;
      stack.forEach(function (cb) {
        try {
          if (cb.handleEvent) {
            cb.handleEvent(event);
          } else {
            cb.call(this, event);
          }
        } catch (e) {
          console.error(`Exception dispatching to callback ${cb}: ${e}`);
        }
      });
    },
  };
})();

