
#define LQ_UNAVAILABLE_METHOD(MSG) __attribute__((unavailable(MSG)))

#define LQ_UNAVAILABLE_INITIALIZER LQ_UNAVAILABLE_METHOD("Unavailable initializer")

#define LQ_UNAVAILABLE_NSOBJECT_INIT \
    - (nonnull instancetype)init LQ_UNAVAILABLE_INITIALIZER; \
    + (nonnull instancetype)new  LQ_UNAVAILABLE_INITIALIZER;
