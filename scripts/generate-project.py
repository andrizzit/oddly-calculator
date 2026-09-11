#!/usr/bin/env python3
"""Generate the checked-in Xcode project with Python's standard library only."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
objects = {}

def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def add(name, value):
    key = uid(name)
    objects[key] = value
    return key

def quote(value):
    return json.dumps(str(value))

def array(values):
    return '(' + ', '.join(values) + (',' if values else '') + ')'

def obj(**values):
    return '{ ' + ' '.join(f'{k} = {v};' for k, v in values.items()) + ' }'

def file(path, filetype):
    return add('file:' + path, obj(isa='PBXFileReference', lastKnownFileType=filetype,
                                 path=quote(path), sourceTree=quote('<group>')))

app_sources = [str(p.relative_to(ROOT)) for p in sorted((ROOT / 'Oddly').glob('*.swift'))]
ui_sources = [str(p.relative_to(ROOT)) for p in sorted((ROOT / 'OddlyUITests').glob('*.swift'))]
if not app_sources:
    raise SystemExit('No app Swift files found. Run after sources have been created.')
source_refs = [file(p, 'sourcecode.swift') for p in app_sources]
ui_refs = [file(p, 'sourcecode.swift') for p in ui_sources]
resources = [file('Oddly/Assets.xcassets', 'folder.assetcatalog'),
             file('Oddly/PrivacyInfo.xcprivacy', 'text.xml')]
info = file('Oddly/Info.plist', 'text.plist.xml')
config = file('Oddly/Config.xcconfig', 'text.xcconfig')
app_product = add('product:app', obj(isa='PBXFileReference', explicitFileType='wrapper.application',
                    includeInIndex='0', path=quote('Oddly.app'), sourceTree='BUILT_PRODUCTS_DIR'))
test_product = add('product:tests', obj(isa='PBXFileReference', explicitFileType='wrapper.cfbundle',
                    includeInIndex='0', path=quote('OddlyUITests.xctest'), sourceTree='BUILT_PRODUCTS_DIR'))
products = add('products', obj(isa='PBXGroup', children=array([app_product, test_product]),
                              name='Products', sourceTree=quote('<group>')))
main_group = add('main-group', obj(isa='PBXGroup', children=array(source_refs + ui_refs + resources + [info, config, products]),
                                  sourceTree=quote('<group>')))
package = add('package', obj(isa='XCLocalSwiftPackageReference', relativePath=quote('.')))
package_product = add('package-product', obj(isa='XCSwiftPackageProductDependency', package=package, productName='CalculatorCore'))
package_build = add('package-build', obj(isa='PBXBuildFile', productRef=package_product))

def phase(name, isa, refs):
    builds = [add('build:' + name + ref, obj(isa='PBXBuildFile', fileRef=ref)) for ref in refs]
    return add(name, obj(isa=isa, buildActionMask='2147483647', files=array(builds), runOnlyForDeploymentPostprocessing='0'))

sources_phase = phase('sources', 'PBXSourcesBuildPhase', source_refs)
resources_phase = phase('resources', 'PBXResourcesBuildPhase', resources)
frameworks_phase = add('frameworks', obj(isa='PBXFrameworksBuildPhase', buildActionMask='2147483647',
                     files=array([package_build]), runOnlyForDeploymentPostprocessing='0'))
ui_phase = phase('ui-sources', 'PBXSourcesBuildPhase', ui_refs)
ui_frameworks = phase('ui-frameworks', 'PBXFrameworksBuildPhase', [])
ui_resources = phase('ui-resources', 'PBXResourcesBuildPhase', [])

def configs(name, settings, base=None):
    entries = []
    for mode in ['Debug', 'Release']:
        values = dict(settings)
        values['SWIFT_OPTIMIZATION_LEVEL'] = quote('-Onone' if mode == 'Debug' else '-O')
        values['DEBUG_INFORMATION_FORMAT'] = quote('dwarf' if mode == 'Debug' else 'dwarf-with-dsym')
        values['ONLY_ACTIVE_ARCH'] = 'YES' if mode == 'Debug' else 'NO'
        if mode == 'Debug':
            values['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = quote('DEBUG $(inherited)')
            values['ENABLE_TESTABILITY'] = 'YES'
        else:
            values['SWIFT_COMPILATION_MODE'] = 'wholemodule'
        args = dict(isa='XCBuildConfiguration', buildSettings=obj(**values), name=mode)
        if base:
            args['baseConfigurationReference'] = base
        entries.append(add(f'{name}:{mode}', obj(**args)))
    return add(name + ':configs', obj(isa='XCConfigurationList', buildConfigurations=array(entries),
               defaultConfigurationIsVisible='0', defaultConfigurationName='Release'))

project_config = configs('project', dict(CLANG_ENABLE_MODULES='YES', CLANG_ENABLE_OBJC_ARC='YES',
    SDKROOT='iphoneos', IPHONEOS_DEPLOYMENT_TARGET='17.0', SWIFT_VERSION='5.0',
    ENABLE_USER_SCRIPT_SANDBOXING='YES', GCC_WARN_UNDECLARED_SELECTOR='YES',
    CLANG_WARN_DOCUMENTATION_COMMENTS='YES', CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER='YES'))
app_config = configs('app', dict(PRODUCT_NAME=quote('$(TARGET_NAME)'), INFOPLIST_FILE=quote('Oddly/Info.plist'),
    ASSETCATALOG_COMPILER_APPICON_NAME='AppIcon', GENERATE_INFOPLIST_FILE='NO',
    SUPPORTED_PLATFORMS=quote('iphoneos iphonesimulator'), SUPPORTS_MACCATALYST='NO',
    LD_RUNPATH_SEARCH_PATHS=quote('$(inherited) @executable_path/Frameworks')), config)
ui_config = configs('tests', dict(PRODUCT_NAME=quote('$(TARGET_NAME)'),
    PRODUCT_BUNDLE_IDENTIFIER=quote('$(ODDLY_BUNDLE_IDENTIFIER).uitests'), GENERATE_INFOPLIST_FILE='YES',
    TEST_TARGET_NAME='Oddly', TARGETED_DEVICE_FAMILY=quote('1,2'), CODE_SIGN_STYLE='Automatic',
    SUPPORTED_PLATFORMS=quote('iphoneos iphonesimulator')), config)
app_target = add('target:app', obj(isa='PBXNativeTarget', buildConfigurationList=app_config,
    buildPhases=array([sources_phase, frameworks_phase, resources_phase]), buildRules='()', dependencies='()',
    name='Oddly', packageProductDependencies=array([package_product]), productName='Oddly',
    productReference=app_product, productType=quote('com.apple.product-type.application')))
proxy = add('proxy', obj(isa='PBXContainerItemProxy', containerPortal=uid('project'), proxyType='1',
                         remoteGlobalIDString=app_target, remoteInfo='Oddly'))
dependency = add('test-dependency', obj(isa='PBXTargetDependency', target=app_target, targetProxy=proxy))
ui_target = add('target:tests', obj(isa='PBXNativeTarget', buildConfigurationList=ui_config,
    buildPhases=array([ui_phase, ui_frameworks, ui_resources]), buildRules='()', dependencies=array([dependency]),
    name='OddlyUITests', productName='OddlyUITests', productReference=test_product,
    productType=quote('com.apple.product-type.bundle.ui-testing')))
project = add('project', obj(isa='PBXProject', attributes=obj(BuildIndependentTargetsInParallel='YES',
    LastUpgradeCheck='2600', TargetAttributes='{ ' + app_target + ' = { CreatedOnToolsVersion = 26.0; }; ' + ui_target +
    ' = { CreatedOnToolsVersion = 26.0; TestTargetID = ' + app_target + '; }; }'),
    buildConfigurationList=project_config, compatibilityVersion=quote('Xcode 14.0'), developmentRegion='en',
    hasScannedForEncodings='0', knownRegions=array(['en', 'Base']), mainGroup=main_group, productRefGroup=products,
    packageReferences=array([package]), projectDirPath=quote(''), projectRoot=quote(''), targets=array([app_target, ui_target])))
project_dir = ROOT / 'Oddly.xcodeproj'
project_dir.mkdir(exist_ok=True)
content = '// !$*UTF8*$!\n{\n archiveVersion = 1;\n classes = {};\n objectVersion = 56;\n objects = {\n'
content += '\n'.join(f'  {key} = {value};' for key, value in objects.items())
content += '\n };\n rootObject = ' + project + ';\n}\n'
(project_dir / 'project.pbxproj').write_text(content)
scheme_dir = project_dir / 'xcshareddata' / 'xcschemes'
scheme_dir.mkdir(parents=True, exist_ok=True)
def ref(target, name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:Oddly.xcodeproj"/>'
(scheme_dir / 'Oddly.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref(app_target, 'Oddly.app')}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
  <Testables><TestableReference skipped="NO">{ref(ui_target, 'OddlyUITests.xctest')}</TestableReference></Testables>
 </TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
  <BuildableProductRunnable runnableDebuggingMode="0">{ref(app_target, 'Oddly.app')}</BuildableProductRunnable>
 </LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref(app_target, 'Oddly.app')}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(f'Generated Oddly.xcodeproj: {len(app_sources)} app files, {len(ui_sources)} UI test files')
