/**
 * @constructor Class
 *
 * Constructs a new Class. Arguments marked as optional must be
 * either entirely elided, or they must have the exact type
 * specified.
 *
 * @param {string} name The class's as it will appear when toString
 *     is called, as well as in stack traces.
 *     @optional
 * @param {function} base The base class for this module. May be any
 *     callable object.
 *     @optional
 *     @default Class
 * @param {Object} prototype The prototype for instances of this
 *     object. The object itself is copied and not used as a prototype
 *     directly.
 * @param {Object} classProperties The class properties for the new
 *     module constructor. More than one may be provided.
 *     @optional
 *
 * @returns {function} The constructor for the resulting class.
 */



function Class() {

    var args = Array.slice(arguments);
    if (isString(args[0]))
        var name = args.shift();
    var superclass = Class;
    if (callable(args[0]))
        superclass = args.shift();

    if (loaded.util && util.haveGecko("6.0a1")) // Bug 657418.
        var Constructor = function Constructor() {
            var self = Object.create(Constructor.prototype, {
                constructor: { value: Constructor },
            });
            self.instance = self;
            var res = self.init.apply(self, arguments);
            return res !== undefined ? res : self;
        };
    else
        var Constructor = eval(String.replace(<![CDATA[
            (function constructor(PARAMS) {
                var self = Object.create(Constructor.prototype, {
                    constructor: { value: Constructor },
                });
                self.instance = self;
                var res = self.init.apply(self, arguments);
                return res !== undefined ? res : self;
            })]]>,
            "constructor", (name || superclass.className).replace(/\W/g, "_"))
                .replace("PARAMS", /^function .*?\((.*?)\)/.exec(args[0] && args[0].init || Class.prototype.init)[1]
                                                           .replace(/\b(self|res|Constructor)\b/g, "$1_")));

    Constructor.className = name || superclass.className || superclass.name;

    if ("init" in superclass.prototype)
        Constructor.__proto__ = superclass;
    else {
        let superc = superclass;
        superclass = function Shim() {};
        Class.extend(superclass, superc, {
            init: superc
        });
        superclass.__proto__ = superc;
    }

    Class.extend(Constructor, superclass, args[0]);
    update(Constructor, args[1]);
    Constructor.__proto__ = superclass;
    args = args.slice(2);
    Array.forEach(args, function (obj) {
        if (callable(obj))
            obj = obj.prototype;
        update(Constructor.prototype, obj);
    });
    return Constructor;
}

if (Cu.getGlobalForObject)
    Class.objectGlobal = function (caller) {
        try {
            return Cu.getGlobalForObject(caller);
        }
        catch (e) {
            return null;
        }
    };
else
    Class.objectGlobal = function (caller) {
        while (caller.__parent__)
            caller = caller.__parent__;
        return caller;
    };

/**
 * @class Class.Property
 * A class which, when assigned to a property in a Class's prototype
 * or class property object, defines that property's descriptor
 * rather than its value. If the desc object has an init property, it
 * will be called with the property's name before the descriptor is
 * assigned.
 *
 * @param {Object} desc The property descriptor.
 */
Class.Property = function Property(desc) update(
    Object.create(Property.prototype), desc || { configurable: true, writable: true });
Class.Property.prototype.init = function () {};
/**
 * Extends a subclass with a superclass. The subclass's
 * prototype is replaced with a new object, which inherits
 * from the superclass's prototype, {@see update}d with the
 * members of *overrides*.
 *
 * @param {function} subclass
 * @param {function} superclass
 * @param {Object} overrides @optional
 */
Class.extend = function extend(subclass, superclass, overrides) {
    subclass.superclass = superclass;

    subclass.prototype = Object.create(superclass.prototype);
    update(subclass.prototype, overrides);
    subclass.prototype.constructor = subclass;
    subclass.prototype._class_ = subclass;

    if (superclass.prototype.constructor === objproto.constructor)
        superclass.prototype.constructor = superclass;
}

/**
 * Memoizes the value of a class property to the value returned by
 * the passed function the first time the property is accessed.
 *
 * @param {function(string)} getter The function which returns the
 *      property's value.
 * @return {Class.Property}
 */
Class.memoize = function memoize(getter, wait)
    Class.Property({
        configurable: true,
        enumerable: true,
        init: function (key) {
            let done = false;

            if (wait)
                this.get = function replace() {
                    let obj = this.instance || this;
                    Object.defineProperty(obj, key,  {
                        configurable: true, enumerable: false,
                        get: function get() {
                            util.waitFor(function () done);
                            return this[key];
                        }
                    });

                    util.yieldable(function () {
                        let wait;
                        for (var res in getter.call(obj)) {
                            if (wait !== undefined)
                                yield wait;
                            wait = res;
                        }
                        Class.replaceProperty(obj, key, res);
                        done = true;
                    })();

                    return this[key];
                };
            else
                this.get = function replace() {
                    let obj = this.instance || this;
                    Class.replaceProperty(obj, key, null);
                    return Class.replaceProperty(obj, key, getter.call(this, key));
                };

            this.set = function replace(val) Class.replaceProperty(this.instance || this, val);
        }
    });

Class.replaceProperty = function replaceProperty(obj, prop, value) {
    Object.defineProperty(obj, prop, { configurable: true, enumerable: true, value: value, writable: true });
    return value;
};
Class.toString = function toString() "[class " + this.className + "]";
Class.prototype = {
    /**
     * Initializes new instances of this class. Called automatically
     * when new instances are created.
     */
    init: function c_init() {},

    withSavedValues: function withSavedValues(names, callback, self) {
        let vals = names.map(function (name) this[name], this);
        try {
            return callback.call(self || this);
        }
        finally {
            names.forEach(function (name, i) this[name] = vals[i], this);
        }
    },

    toString: function C_toString() {
        if (this.toStringParams)
            var params = "(" + this.toStringParams.map(function (m) isArray(m)  ? "[" + m + "]" :
                                                                    isString(m) ? m.quote() : String(m))
                                   .join(", ") + ")";
        return "[instance " + this.constructor.className + (params || "") + "]";
    },

    /**
     * Executes *callback* after *timeout* milliseconds. The value of
     * 'this' is preserved in the invocation of *callback*.
     *
     * @param {function} callback The function to call after *timeout*
     * @param {number} timeout The time, in milliseconds, to wait
     *     before calling *callback*.
     * @returns {nsITimer} The timer which backs this timeout.
     */
    timeout: function timeout(callback, timeout) {
        const self = this;
        function timeout_notify(timer) {
            if (self.stale ||
                    util.rehashing && !isinstance(Cu.getGlobalForObject(callback), ["BackstagePass"]))
                return;
            util.trapErrors(callback, self);
        }
        return services.Timer(timeout_notify, timeout || 0, services.Timer.TYPE_ONE_SHOT);
    },

    /**
     * Updates this instance with the properties of the given objects.
     * Like the update function, but with special semantics for
     * localized properties.
     */
    update: function update() {
        let self = this;
        // XXX: Duplication.

        for (let i = 0; i < arguments.length; i++) {
            let src = arguments[i];
            Object.getOwnPropertyNames(src || {}).forEach(function (k) {
                let desc = Object.getOwnPropertyDescriptor(src, k);
                if (desc.value instanceof Class.Property)
                    desc = desc.value.init(k, this) || desc.value;

                if (typeof desc.value === "function") {
                    let func = desc.value.wrapped || desc.value;
                    func.__defineGetter__("super", function () Object.getPrototypeOf(self)[k]);
                    func.superapply = function superapply(self, args)
                        let (meth = Object.getPrototypeOf(self)[k])
                            meth && meth.apply(self, args);
                    func.supercall = function supercall(self)
                        func.superapply(self, Array.slice(arguments, 1));
                }
                try {
                    if ("value" in desc && i in this.localizedProperties)
                        this[k] = desc.value;
                    else
                        Object.defineProperty(this, k, desc);
                }
                catch (e) {}
            }, this);
        }
    }
};
Class.makeClosure = function makeClosure() {
    const self = this;
    function closure(fn) {
        function _closure() {
            try {
                return fn.apply(self, arguments);
            }
            catch (e if !(e instanceof FailedAssertion)) {
                util.reportError(e);
                throw e.stack ? e : Error(e);
            }
        }
        _closure.wrapped = fn;
        return _closure;
    }

    iter(properties(this), properties(this, true)).forEach(function (k) {
        if (!__lookupGetter__.call(this, k) && callable(this[k]))
            closure[k] = closure(this[k]);
        else if (!(k in closure))
            Object.defineProperty(closure, k, {
                configurable: true,
                enumerable: true,
                get: function get_proxy() self[k],
                set: function set_proxy(val) self[k] = val,
            });
    }, this);

    return closure;
};
memoize(Class.prototype, "closure", Class.makeClosure);

/**
 * A base class generator for classes which implement XPCOM interfaces.
 *
 * @param {nsIIID|[nsIJSIID]} interfaces The interfaces which the class
 *      implements.
 * @param {Class} superClass A super class. @optional
 * @returns {Class}
 */
function XPCOM(interfaces, superClass) {
    interfaces = Array.concat(interfaces);

    let shim = interfaces.reduce(function (shim, iface) shim.QueryInterface(iface),
                                 CC["@dactyl.googlecode.com/base/xpc-interface-shim"].createInstance());

    let res = Class("XPCOM(" + interfaces + ")", superClass || Class, update(
        iter.toObject([k, v === undefined || callable(v) ? function stub() null : v]
                      for ([k, v] in Iterator(shim))),
        { QueryInterface: XPCOMUtils.generateQI(interfaces) }));
    shim = interfaces = null;
    return res;
}
