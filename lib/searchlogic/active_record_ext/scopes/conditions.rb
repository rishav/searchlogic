require Dir[File.dirname(__FILE__) + '/conditions/chronic_support.rb'].first
require Dir[File.dirname(__FILE__) + '/conditions/condition.rb'].first
Dir[File.dirname(__FILE__) + '/conditions/*.rb'].each { |f| require(f) }

module Searchlogic
  module ActiveRecordExt
    module Scopes
      module Conditions
        def respond_to?(*args)
          name = args.first
          scopeable?(name)  || super
        end
          
        def association_names
          reflect_on_all_associations.map{|a| a.name.to_s}
        end

        def association_in_method( method)
          first_association = reflect_on_all_associations.find{|a| /^#{a.name.to_s}/.match(method.to_s)}
          if first_association
            klassname = first_association.name.to_s
            new_method = /[#{klassname}|#{klassname.singularize}]_(.*)/.match(method)[1]
            [klassname, new_method]
          else
            nil
          end
        end

        def tables
          ActiveRecord::Base.connection.tables
        end

        def memoized_scopes
          @memoized_scopes ||= {}
        end
        private

        def method_missing(method, *args, &block) 
          std_method = ScopeReflection.new(method).condition
          generate_scope(std_method, args, &block) || super 
        end

        def generate_scope(method, args, &block)
          condition_klasses.each do |ck|
              scope = ck.generate_scope(self, method, args, &block)
            if scope 
              memoized_scopes[method.to_sym]
              return scope
            end
          end
          nil
        end

        def scopeable?(method)
          if ActiveRecord::Base.connected?
            define_matchers_on_scope_reflection
            ScopeReflection.authorized?(method)
          else
            false
          end
        end

        def define_matchers_on_scope_reflection
          ##Before the database connects, define the matchers 
          ## on scope reflection(only once)
          unless ScopeReflection.respond_to?(:searchlogic_methods) 
            lambda { 
              conditions = condition_klasses
              Searchlogic::ScopeReflection.class_eval do 
                define_method(:searchlogic_methods) do 
                  conditions.map { |kc| kc.matcher }.compact
                end
              end
            }.call  
          end    
        end
        

        def condition_klasses
         [  
            Polymorphic,
            Or,            
            Any,
            GreaterThanOrEqualTo,
            LessThanOrEqualTo,
            Equals,
            BeginsWith,
            DoesNotEqual,
            DoesNotBeginWith,
            EndsWith,
            DoesNotEndWith,
            NotLike,
            Like,
            GreaterThan,
            LessThan,
            NotNull,
            Null,
            NotBlank,
            Blank,
            All,
            Boolean,
            NormalizeInput,
            Joins,
            NamedScopes,
            AscendBy,
            DescendBy,
          ] 
        end
      end
    end
  end
end