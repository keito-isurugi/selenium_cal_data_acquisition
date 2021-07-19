require 'selenium-webdriver'
require 'byebug'
require 'csv'

# おまじない
bom = %w(EF BB BF).map { |e| e.hex.chr }.join

# CSVファイル新規作成、各項目作成、保存
csv_file = CSV.generate(bom) do |csv|
  csv << ["No", "食品名", "量(g)", "カロリー(kcal) ", "タンパク質(g)", "脂質(g)", "炭水化物(g)"]
end
File.open("calorie_data.csv", "w") do |file|
  file.write(csv_file)
end
 
# ブラウザ起動
d = Selenium::WebDriver.for :chrome
# 待ち時間
wait = Selenium::WebDriver::Wait.new(:timeout => 10)

# サイトにアクセス
d.get("https://calorie.slism.jp/")

# 空の配列を作成
xpaths = []
urls1 = []
pages = []
urls2 = []

# 食品、料理名のxpathを配列xpathsに追加
xpaths << d.find_element(:xpath, '//*[@id="contentsTokushuRight"]/aside[1]/div[2]/ul/li[2]/ul') << d.find_element(:xpath, '//*[@id="contentsTokushuRight"]/aside[1]/div[2]/ul/li[4]/ul')

# 配列xpathsの分だけ、中要素(野菜、穀物など)のリンクを配列urls1に追加
xpaths.each do |xpath|
  wait.until { xpath.find_elements(:tag_name, 'li').size > 0 }
  xpath.find_elements(:tag_name, 'li').each do |li|
    urls1 << li.find_element(:tag_name, 'a').attribute("href")
  end
end

# 中要素の各ページリンクを取得し配列pagesに追加
urls1.each do |url1|
  d.get(url1)
  wait.until { d.find_element(:id, 'pager').find_elements(:tag_name, 'a').size > 0 }
  d.find_element(:id, 'pager').find_elements(:tag_name, 'a').each do |page|
    pages << page.attribute("href")
  end
end

# 配列pages内のページにアクセスし、少要素のリンクを取得、配列urls2に追加
pages.uniq.each do |page|
  d.get(page)
  wait.until { d.find_elements(:class, 'soshoku_a').size > 0 }
  d.find_elements(:class, 'soshoku_a').each do |url2|
    urls2 << url2.attribute("href")
  end
  puts(urls2)
end

# CSVファイル項目に取得データを代入
i = 1
urls2.each do |url2|
  d.get(url2)
  name = d.find_element(:id, 'itemImg').find_element(:tag_name, 'h2').text
  amount = d.find_element(:id, 'serving_content').text
  calorie = d.find_element(:class, 'singlelistKcal').text
  protein = d.find_element(:id, 'protein_content').text
  fat = d.find_element(:id, 'fat_calories').text
  carb = d.find_element(:id, 'carb_content').text
  CSV.open("cal_data.csv", "a") do |data|
    data << [i, name, amount, calorie, protein, fat, carb]
  end
  i += 1
end


sleep 2
d.quit
