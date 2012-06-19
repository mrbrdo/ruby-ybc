- defineclass(0):
rb_define_class_under(::cbase, "::name", ::zuper)

- defineclass(3):
rb_define_class("::name", ::zuper)

- defineclass(1):
rb_singleton_class(::cbase)

- defineclass(2):
rb_define_module_under(::cbase, "::name")

- defineclass(5):
rb_define_module("::name")

- empty_placeholder
// for easier regexp