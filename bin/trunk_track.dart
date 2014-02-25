library trunk_track;

import 'package:git/git.dart';
import 'package:path/path.dart' as p;

import 'package:trunk_track/commit_data.dart';

void main() {
  var current = p.current;

  GitDir.fromExisting(current)
    .then((gitDir) => gitDir.getCommits(_TRUNK_BRARCH))
    .then(inspectCommits)
    .then(_printV1_2Data);
}

void _printV1_2Data(List<CommitData> commitDataList) {
  for(CommitData data in commitDataList) {
      print([data.svnCommitNumber, data.merges.length, data.commitSha].join('\t'));
  }
}

const _TRUNK_BRARCH = 'remotes/trunk/master';
