module App
  module ReactiveMixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def reactive(*attrs)
        attrs.each do |attr|
          ivar = :"@#{attr}"
          callbacks_ivar = :"@_#{attr}_changed_callback"

          define_method(attr) do
            instance_variable_get(ivar)
          end

          define_method(:"#{attr}=") do |new_val|
            old_val = instance_variable_get(ivar)
            if old_val != new_val
              instance_variable_set(ivar, new_val)

              # Per-signal callbacks
              callbacks = instance_variable_get(callbacks_ivar) || []
              callbacks.each { |cb| cb.call(new_val, old_val) }

              # Global on_change callbacks — also receive the signal name
              global = @_global_change_callbacks || []
              global.each { |cb| cb.call(attr, new_val, old_val) }
            end
          end

          define_method(:"on_#{attr}_change") do |&block|
            callbacks = instance_variable_get(callbacks_ivar) || []
            instance_variable_set(callbacks_ivar, callbacks << block)
          end
        end
      end
    end

    # Global watcher — fires on ANY signal change
    def on_change(&block)
      @_global_change_callbacks ||= []
      @_global_change_callbacks << block
    end
  end
end
