// 修复参数
fixMethod('HFTestClass', 'changePrames:', 2,
          function(instance, originInvocation, originArguments) {
            var params = new Array();
            params[0] = '🤪🤪🤪惊喜不惊喜，我被改掉了，我是新参数！'
            setInvocationArguments(originInvocation,params);
          });
