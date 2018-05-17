/**
 * Several macros simplifying use of weak references to self inside blocks
 * which goal is to reduce risk of retain cycles.
 *
 * Version 2. Uses GCC statement expressions
 * instead of capturing self via block closure.
 *
 * Example:
 * @code
 
 @interface Example : NSObject{
 int _i;
 }
 @property (nonatomic,copy) void(^block)(void);
 @end
 
 @implementation Example
 -(void)someMethod{
 self.block = weakifySelf(^{
 // Self may be nil here
 [self doSomeWork];
 strongifyAndReturnIfNil(self);
 // Self is strong and not nil.
 // We can do ivars dereferencing
 // and other stuff safely
 self->_i = 42;
 });
 }
 @end
 
 * @endcode
 */

/**
 * Takes a block of any signature as an argument
 * and makes all references to self in it weak.
 */
#define weakifySelf(BLOCK) ({ \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
id __weak _weak_self = self; \
__typeof(self) __weak self = _weak_self; \
BLOCK; \
_Pragma("clang diagnostic pop") \
})

/**
 * Creates a strong reference to a variable
 * that will shadow the original
 */
#define strongify(VAR) \
id _strong_##VAR = VAR; \
__typeof(VAR) __strong VAR = _strong_##VAR;

/**
 * Creates a strong reference to a variable and returns if it is nil
 */
#define strongifyAndReturnIfNil(VAR) \
strongify(VAR) \
if (!(VAR)){ return;}
