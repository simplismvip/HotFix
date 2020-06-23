// 替换崩溃方法
fixMethod('HFTestClass', 'instanceReplace:', 1,
          function() {
                runMethod("HFTestClass","replaceLog:");
          });
