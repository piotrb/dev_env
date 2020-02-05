class Module
  def import(*methods, from:, to_class: false)
    methods.each do |method|
      m = from.instance_method(method)
      if to_class
        define_singleton_method method, m
      else
        define_method method, m
      end
    end
  end
end

class Object
  def import(*methods, from:)
    methods.each do |method|
      m = from.instance_method(method)
      define_method method, m
    end
  end
end
