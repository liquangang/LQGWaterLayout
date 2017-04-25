Pod::Spec.new do |s|
s.name         = "LQGWaterLayout"
s.version      = "1.0.0"
s.ios.deployment_target = '8.0'
s.summary      = "瀑布流布局开源库"
s.description  = <<-DESC
                       LQGWaterLayout 瀑布流布局开源库
                    DESC
s.homepage     = "https://github.com/liquangang/LQGWaterLayout"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author       = { "liquangang" => "1347336730@qq.com" }
s.source       = { :git => "https://github.com/liquangang/LQGWaterLayout.git", :tag => "#{s.version}" }
s.source_files  = "LQGWaterLayout/**/*"
end
