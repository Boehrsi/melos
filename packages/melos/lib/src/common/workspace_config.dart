/*
 * Copyright (c) 2016-present Invertase Limited & Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this library except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'utils.dart';
import 'workspace_scripts.dart';

String get _yamlConfigDefault {
  return '''
name: Melos
packages:
  - packages/**
''';
}

// TODO document & cleanup class members.
// TODO validation of config e.g. name should be alphanumeric dasherized/underscored
class MelosWorkspaceConfig {
  MelosWorkspaceConfig._(this._name, this._path, this._yamlContents);

  final String _name;

  String get name => _name;

  final String _path;

  String get path => _path;

  MelosWorkspaceScripts get scripts =>
      MelosWorkspaceScripts(_yamlContents['scripts'] as Map ?? {});

  String get version => _yamlContents['version'] as String;

  bool get generateIntellijIdeFiles {
    final ide = _yamlContents['ide'] as Map ?? {};
    if (ide['intellij'] == false) return false;
    if (ide['intellij'] == true) return true;
    return true;
  }

  final Map _yamlContents;

  List<String> get packages {
    final patterns = _yamlContents['packages'] as YamlList;
    if (patterns == null) return <String>[];
    return List<String>.from(patterns);
  }

  /// Glob patterns defined in "melos.yaml" ignore of packages to always exclude
  /// regardless of any custom CLI filter options.
  List<String> get ignore {
    final patterns = _yamlContents['ignore'] as YamlList;
    if (patterns == null) return <String>[];
    return List<String>.from(patterns);
  }

  static Future<MelosWorkspaceConfig> fromDirectory(Directory directory) async {
    if (!isWorkspaceDirectory(directory)) {
      // Allow melos to use a project without a `melos.yaml` file if a `packages`
      // directory exists.
      final packagesDirectory =
          Directory(joinAll([directory.path, 'packages']));
      if (packagesDirectory.existsSync()) {
        return MelosWorkspaceConfig._(
            'Melos', directory.path, loadYaml(_yamlConfigDefault) as Map);
      }

      return null;
    }

    final melosYamlPath = melosYamlPathForDirectory(directory);
    final yamlContents = await loadYamlFile(melosYamlPath);
    if (yamlContents == null) {
      return null;
    }

    return MelosWorkspaceConfig._(
        yamlContents['name'] as String, directory.path, yamlContents);
  }
}
