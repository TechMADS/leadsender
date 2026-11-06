class RejectedCandidate {
  final String raw;
  final String reason;
  RejectedCandidate(this.raw, this.reason);
}

class ExtractedNumber {
  final String normalized;
  final String original;
  final String? name;
  final String? location;
  final String? enquiry;
  final String? siteStatus;
  final String? source;

  ExtractedNumber(
      this.normalized,
      this.original, {
        this.name,
        this.location,
        this.enquiry,
        this.siteStatus, // ADD THIS
        this.source,
      });
}

class ExtractionResult {
  final List<ExtractedNumber> valid;
  final List<RejectedCandidate> rejected;
  final int duplicatesRemoved;
  final List<ExtractedNumber> ambiguous;

  ExtractionResult({
    required this.valid,
    required this.rejected,
    required this.duplicatesRemoved,
    required this.ambiguous,
  });

  int get totalCandidates =>
      valid.length + rejected.length + duplicatesRemoved + ambiguous.length;
}

// class RejectedCandidate {
//   final String raw;
//   final String reason;
//   RejectedCandidate(this.raw, this.reason);
// }
//
// class ExtractedNumber {
//   final String normalized;
//   final String original;
//   ExtractedNumber(this.normalized, this.original);
// }
//
// class ExtractionResult {
//   final List<ExtractedNumber> valid;
//   final List<RejectedCandidate> rejected;
//   final int duplicatesRemoved;
//   final List<ExtractedNumber> ambiguous;
//
//   ExtractionResult({
//     required this.valid,
//     required this.rejected,
//     required this.duplicatesRemoved,
//     required this.ambiguous,
//   });
//
//   int get totalCandidates =>
//       valid.length + rejected.length + duplicatesRemoved + ambiguous.length;
// }