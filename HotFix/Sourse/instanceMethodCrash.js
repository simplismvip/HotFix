// 修复崩溃方法
fixMethod('HFTestClass', 'instanceMethodCrash:', 1,
          function(instance, originInvocation, originArguments) {
              if (originArguments[0] == null) {
                  runError('HFTestClass', 'instanceMethodCrash');
              } else {
                  runInvocation(originInvocation);
              }
          });
