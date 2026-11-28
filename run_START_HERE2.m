% 丟入一組預設 15 秒的配比，測試函數是否能順利回傳「總停等時間」
cost_score = START_HERE2([15, 15, 15, 15]);
disp(['這組號誌的總停等時間為：', num2str(cost_score), ' 秒']);