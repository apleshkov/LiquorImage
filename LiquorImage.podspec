Pod::Spec.new do |s|
    s.name         = 'LiquorImage'
    s.version      = '1.0'
    s.summary      = 'Image downloading, caching, preloading and background transforming. UIImageView category (prefixed) included.'
    s.description = <<-DESC
                    Image downloading, persistent & in-memory caching, preloading and background transforming. UIImageView category (prefixed) included.
                    DESC
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.homepage     = 'https://github.com/apleshkov/LiquorImage'
    s.author             = 'Andrew Pleshkov'
    s.social_media_url   = 'https://twitter.com/AndrewPleshkov'
    s.ios.deployment_target = '7.0'
    s.source       = { :git => 'https://github.com/apleshkov/LiquorImage.git', :branch => 'develop' }
    s.source_files = 'LiquorImage/**/*.{h,m}'
    s.requires_arc = true
end

