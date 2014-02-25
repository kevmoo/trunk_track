library trunk_track;

import 'package:git/git.dart';
import 'package:path/path.dart' as p;

import 'package:trunk_track/commit_data.dart';
import 'package:trunk_track/merge_set.dart';
import 'package:trunk_track/version.dart';

void main() {
  var current = p.current;

  GitDir.fromExisting(current)
    .then((gitDir) => gitDir.getCommits(_TRUNK_BRARCH))
    .then((commits) {
      var data = inspectCommits(commits);

      var v1_2Items = data.where((cd) => cd.version > _V1_1);

      _printV1_2Data(v1_2Items);
    });
}

void _printV1_2Data(List<TrunkCommitData> commitDataList) {
  for(TrunkCommitData data in commitDataList) {
  //  print([data.svnCommitNumber, data.merges.length, data.commitSha].join('\t'));
  }

  var sets = commitDataList.expand((TrunkCommitData cd) => cd.merges);

  var commits = MergeSet.getCommitIds(sets);

  print(commits.length);

}

const _TRUNK_BRARCH = 'remotes/trunk/master';

final _V1_1 = new Version(1, 1, 0);
