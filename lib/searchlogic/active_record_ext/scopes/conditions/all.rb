module Searchlogic
  module ActiveRecordExt
    module Scopes
      module Conditions
        class All < Condition
          def scope
            if applicable?
              where_values = [value].flatten.map{|arg| klass.__send__(new_method, arg).where_values}.
                            flatten.
                            join(" AND ")
              klass.where(where_values)
            end
          end

          def self.matcher
            "_all"
          end
          private
            def value
              if args.count > 1
                args
              else
                args.first
              end
            end

            def new_method
              /(.*)_all/.match(method_name)[1]
            end
            
            def applicable? 
              !(/(#{klass.column_names.join("|")})_.*#{self.class.matcher}$/ =~ method_name).nil?
            end

        end
      end
    end
  end
end

