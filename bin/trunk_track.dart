library trunk_track;

import 'dart:collection';
import 'dart:convert';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;

void main() {
  var current = p.current;

  GitDir.fromExisting(current).then((gitDir) {

    return gitDir.getCommits(_TRUNK_BRARCH);
  }).then(_inspectCommits).then((commitData) {
    for(var data in commitData) {
      print([data.svnCommitNumber, data.merges.length, data.commitSha].join('\t'));
    }
  });
}

List<CommitData> _inspectCommits(LinkedHashMap<String, Commit> commits) {
  return commits.keys
      .map((commitSha) {
    return _parseTrunkCommit(commitSha, commits[commitSha]);
  }).where((data) => data != null).toList();
}

CommitData _parseTrunkCommit(String commitSha, Commit commit) {
  var lines = const LineSplitter().convert(commit.message);

  var lineMatch = _svnIdRegExp.firstMatch(lines.last);

  var svnCommitNumber = int.parse(lineMatch[1]);

  if(svnCommitNumber <= _V1_COMMIT) return null;

  var versionLine = lines.singleWhere((l) => l.startsWith('Version '));
  print(versionLine);

  var mergeLines = lines
      .where((line) => line.startsWith('svn merge -'))
      .toList();

  var merges = new UnmodifiableListView(
      mergeLines.map((line) => new MergeSet(line)).toList());

  return new CommitData(commitSha, svnCommitNumber, commit, merges);
}

class CommitData {
  final List<MergeSet> merges;
  final String commitSha;
  final Commit commit;
  final int svnCommitNumber;

  CommitData(this.commitSha, this.svnCommitNumber, this.commit, this.merges);
}

abstract class MergeSet {
  int get firstCommit;
  int get lastCommit;
  bool containsCommit(int commitNumber);

  factory MergeSet(String line) {
    assert(line.startsWith('svn merge -'));

    var commitMergeMatch = _commitMergeRegExp.firstMatch(line);
    if(commitMergeMatch != null) {
      int mergeCommitNumber = int.parse(commitMergeMatch[1]);
      return new SingleCommitMerge(mergeCommitNumber);
    }

    var rangeMergeMatch = _rangeMergeRegExp.firstMatch(line);
    if(rangeMergeMatch != null) {
      int rangeStart = int.parse(rangeMergeMatch[1]);
      int rangeEnd = int.parse(rangeMergeMatch[2]);

      return new RangeMerge(rangeStart, rangeEnd);
    }

    var revertCommitMergeMatch = _revertCommitMergeRegExp.firstMatch(line);
    if(revertCommitMergeMatch != null) {
      int mergeCommitNumber = int.parse(revertCommitMergeMatch[1]);
      return new RevertCommitMerge(mergeCommitNumber);
    }

    throw new StateError('Not supported: $line');
  }
}

class SingleCommitMerge implements MergeSet {
  final int commit;

  SingleCommitMerge(this.commit) {
    assert(commit != null && commit >= 0);
  }

  int get firstCommit => commit;
  int get lastCommit => commit;
  bool containsCommit(int commitNumber) => commitNumber == commit;
}

class RevertCommitMerge implements MergeSet {
  final int commit;

  RevertCommitMerge(this.commit) {
    assert(commit != null && commit >= 0);
  }

  int get firstCommit => commit;
  int get lastCommit => commit;
  bool containsCommit(int commitNumber) => commitNumber == commit;
}

class RangeMerge implements MergeSet {
  final int firstCommit;
  final int lastCommit;

  bool containsCommit(int commitNumber) =>
      commitNumber >= firstCommit && commitNumber <= lastCommit;

  RangeMerge(this.firstCommit, this.lastCommit) {
    assert(firstCommit < lastCommit);
    assert(firstCommit >= 0);
  }
}

final _svnIdRegExp =
  new RegExp(r'git-svn-id: https://dart.googlecode.com/svn/trunk@(\d+) '
      '260f80e4-7a28-3924-810f-c04153c831b5');

const _BLEEDING_EDGE = 'https://dart.googlecode.com/svn/branches/bleeding_edge trunk';

final _commitMergeRegExp = new RegExp(r'svn merge -c (\d+) ' + _BLEEDING_EDGE);
final _revertCommitMergeRegExp = new RegExp(r'svn merge -c -(\d+) ' + _BLEEDING_EDGE);
final _rangeMergeRegExp = new RegExp(r'svn merge -r ?(\d+):(\d+) ' + _BLEEDING_EDGE);

const _TRUNK_BRARCH = 'remotes/trunk/master';

const _V1_COMMIT = 30798;
