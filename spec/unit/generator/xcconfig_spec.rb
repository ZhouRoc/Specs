require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Generator::XCConfig do
    before do
      specification = fixture_spec('banana-lib/BananaLib.podspec')
      @pod          = Pod::LocalPod.new(specification, config.sandbox, :ios)
      @generator    = Generator::XCConfig.new(config.sandbox, [@pod], './Pods')

    end

    it "returns the sandbox" do
      @generator.sandbox.class.should == Sandbox
    end

    it "returns the pods" do
      @generator.pods.should == [@pod]
    end

    it "returns the path of the pods root relative to the user project" do
      @generator.relative_pods_root.should == './Pods'
    end

    #-----------------------------------------------------------------------#

    before do
      @xcconfig = @generator.generate
    end

    it "generates the xcconfig" do
      @xcconfig.class.should == Xcodeproj::Config
    end

    it "sets to always search the user paths" do
      @xcconfig.to_hash['ALWAYS_SEARCH_USER_PATHS'].should == 'YES'
    end

    it "configures the project to load all members that implement Objective-c classes or categories from the static library" do
      @xcconfig.to_hash['OTHER_LDFLAGS'].should.include '-ObjC'
    end

    it 'does not add the -fobjc-arc to OTHER_LDFLAGS by default as Xcode 4.3.2 does not support it' do
      @xcconfig.to_hash['OTHER_LDFLAGS'].should.not.include("-fobjc-arc")
    end

    it 'adds the -fobjc-arc to OTHER_LDFLAGS if any pods require arc (to support non-ARC projects on iOS 4.0)' do
      @generator.set_arc_compatibility_flag = true
      @pod.top_specification.stubs(:requires_arc).returns(true)
      @xcconfig = @generator.generate
      @xcconfig.to_hash['OTHER_LDFLAGS'].split(" ").should.include("-fobjc-arc")
    end

    it "sets the PODS_ROOT build variable" do
      @xcconfig.to_hash['PODS_ROOT'].should.not == nil
    end

    it "redirects the HEADERS_SEARCH_PATHS to the pod variable" do
      @xcconfig.to_hash['HEADER_SEARCH_PATHS'].should =='${PODS_HEADERS_SEARCH_PATHS}'
    end

    it "sets the PODS_HEADERS_SEARCH_PATHS to look for the public headers as it is overridden in the Pods project" do
      @xcconfig.to_hash['PODS_HEADERS_SEARCH_PATHS'].should =='${PODS_PUBLIC_HEADERS_SEARCH_PATHS}'
    end
    it 'adds the sandbox build headers search paths to the xcconfig, with quotes' do
      expected = "\"#{config.sandbox.build_headers.search_paths.join('" "')}\""
      @xcconfig.to_hash['PODS_BUILD_HEADERS_SEARCH_PATHS'].should == expected
    end

    it 'adds the sandbox public headers search paths to the xcconfig, with quotes' do
      expected = "\"#{config.sandbox.public_headers.search_paths.join('" "')}\""
      @xcconfig.to_hash['PODS_PUBLIC_HEADERS_SEARCH_PATHS'].should == expected
    end

    #-----------------------------------------------------------------------#

    it 'returns the settings that the pods project needs to override' do
      Generator::XCConfig.pods_project_settings.should.not.be.nil
    end

    it 'overrides the relative path of the pods root in the Pods project' do
      Generator::XCConfig.pods_project_settings['PODS_ROOT'].should == '${SRCROOT}'
    end

    it 'overrides the headers search path of the pods project to the build headers folder' do
      expected = '${PODS_BUILD_HEADERS_SEARCH_PATHS}'
      Generator::XCConfig.pods_project_settings['PODS_HEADERS_SEARCH_PATHS'].should == expected
    end

    #-----------------------------------------------------------------------#

    

    it "saves the xcconfig" do
      path = temporary_directory + 'sample.xcconfig'
      @generator.save_as(path)
      generated = Xcodeproj::Config.new(path)
      generated.class.should == Xcodeproj::Config
    end

  end
end
