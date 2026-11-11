#!/usr/bin/env python3
"""Deterministic project generation, requires pbxproj==4.3.3 (tool only)."""
from pathlib import Path
from hashlib import sha256
from pbxproj import XcodeProject
import plistlib
root = Path(__file__).resolve().parents[1]
objects = {}
def obj(key, isa, **fields):
    ident=sha256(key.encode()).hexdigest()[:24].upper()
    objects[ident]={'isa':isa, **fields}
    return ident
refs=[]
def file(path, kind):
    r=obj(path,'PBXFileReference',lastKnownFileType=kind,path=path,sourceTree='SOURCE_ROOT'); refs.append(r); return r
def phase(key, isa, files):
    return obj(key,isa,buildActionMask='2147483647',files=files,runOnlyForDeploymentPostprocessing='0')
def build(key, ref): return obj(key,'PBXBuildFile',fileRef=ref)
appsource=file('App/WatchWeeksApp.swift','sourcecode.swift')
browsingSources = [file('App/' + name + '.swift', 'sourcecode.swift')
                   for name in ['WatchWeeksDesign', 'WatchWeeksGuides', 'WatchWeeksCatalog']]
assets=file('App/Assets.xcassets','folder.assetcatalog')
privacy=file('App/PrivacyInfo.xcprivacy','text.xml')
fonts=[file('App/Fonts/SpaceGrotesk-'+style+'.ttf','file') for style in ['Regular','Medium','SemiBold','Bold']]
fontLicense=file('App/Fonts/OFL.txt','text')
testsource=file('UITests/WatchWeeksUITests.swift','sourcecode.swift')
appProduct=obj('app-product','PBXFileReference',explicitFileType='wrapper.application',path='WatchWeeks.app',sourceTree='BUILT_PRODUCTS_DIR')
testProduct=obj('test-product','PBXFileReference',explicitFileType='wrapper.cfbundle',path='WatchWeeksUITests.xctest',sourceTree='BUILT_PRODUCTS_DIR')
products=obj('products','PBXGroup',children=[appProduct,testProduct],name='Products',sourceTree='<group>')
group=obj('root-group','PBXGroup',children=refs+[products],sourceTree='<group>')
package=obj('core-package','XCLocalSwiftPackageReference',relativePath='.')
core=obj('core-product','XCSwiftPackageProductDependency',productName='WatchWeeksCore')
corebuild=obj('core-build','PBXBuildFile',productRef=core)
def configs(key, common):
    ids=[]
    for mode in ['Debug','Release']:
        values=dict(common)
        values.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if mode=='Debug' else '-O',DEBUG_INFORMATION_FORMAT='dwarf' if mode=='Debug' else 'dwarf-with-dsym')
        if mode=='Debug':
            values['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'
            values['ONLY_ACTIVE_ARCH']='YES'
        ids.append(obj(key+mode,'XCBuildConfiguration',buildSettings=values,name=mode))
    return obj(key+'configs','XCConfigurationList',buildConfigurations=ids,defaultConfigurationIsVisible='0',defaultConfigurationName='Release')
base={'IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'iphoneos','SWIFT_VERSION':'6.0','CLANG_ENABLE_MODULES':'YES','ENABLE_USER_SCRIPT_SANDBOXING':'YES'}
projectConfigs=configs('project',base)
settings={'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.watchweeks.app','MARKETING_VERSION':'1.0.2','CURRENT_PROJECT_VERSION':'1','TARGETED_DEVICE_FAMILY':'1','CODE_SIGN_STYLE':'Automatic','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_FILE':'App/Info.plist','INFOPLIST_KEY_CFBundleDisplayName':'WatchWeeks','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.lifestyle','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations':'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','SWIFT_EMIT_LOC_STRINGS':'YES'}
app=obj('app','PBXNativeTarget',buildConfigurationList=configs('app',settings),buildPhases=[phase('app-src','PBXSourcesBuildPhase',[build('app-src-build',appsource)] +
    [build('browse-src-' + str(i), ref) for i, ref in enumerate(browsingSources)]),phase('app-frameworks','PBXFrameworksBuildPhase',[corebuild]),phase('app-resources','PBXResourcesBuildPhase',[build('assets-build',assets),build('privacy-build',privacy)]+[build('font-'+str(i),f) for i,f in enumerate(fonts)]+[build('font-license-build',fontLicense)])],buildRules=[],dependencies=[],name='WatchWeeks',packageProductDependencies=[core],productName='WatchWeeks',productReference=appProduct,productType='com.apple.product-type.application')
projectID=sha256(b'project').hexdigest()[:24].upper()
proxy=obj('proxy','PBXContainerItemProxy',containerPortal=projectID,proxyType='1',remoteGlobalIDString=app,remoteInfo='WatchWeeks')
dep=obj('dependency','PBXTargetDependency',target=app,targetProxy=proxy)
test=obj('tests','PBXNativeTarget',buildConfigurationList=configs('uitest',{'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.watchweeks.app.uitests','GENERATE_INFOPLIST_FILE':'YES','TARGETED_DEVICE_FAMILY':'1','TEST_TARGET_NAME':'WatchWeeks','CODE_SIGN_STYLE':'Automatic'}),buildPhases=[phase('test-src','PBXSourcesBuildPhase',[build('test-src-build',testsource)]),phase('test-frameworks','PBXFrameworksBuildPhase',[])],buildRules=[],dependencies=[dep],name='WatchWeeksUITests',productName='WatchWeeksUITests',productReference=testProduct,productType='com.apple.product-type.bundle.ui-testing')
obj('project','PBXProject',attributes={'LastUpgradeCheck':'2600','BuildIndependentTargetsInParallel':'YES'},buildConfigurationList=projectConfigs,compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings='0',knownRegions=['en','Base'],mainGroup=group,productRefGroup=products,projectDirPath='',projectRoot='',targets=[app,test],packageReferences=[package])
path=root/'WatchWeeks.xcodeproj'; path.mkdir(exist_ok=True)
XcodeProject({'archiveVersion':'1','classes':{},'objectVersion':'56','objects':objects,'rootObject':projectID},str(path/'project.pbxproj')).save()
schemes=path/'xcshareddata/xcschemes'; schemes.mkdir(parents=True,exist_ok=True)
def ref(ident,name,product): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:WatchWeeks.xcodeproj"/>'
(schemes/'WatchWeeks.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref(app,'WatchWeeks','WatchWeeks.app')}</BuildActionEntry><BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">{ref(test,'WatchWeeksUITests','WatchWeeksUITests.xctest')}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref(test,'WatchWeeksUITests','WatchWeeksUITests.xctest')}</TestableReference></Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app,'WatchWeeks','WatchWeeks.app')}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app,'WatchWeeks','WatchWeeks.app')}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
print('Generated project and shared scheme; Xcode validation still required.')
