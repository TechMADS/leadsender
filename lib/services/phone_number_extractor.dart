import '../models/extraction_result.dart';

class PhoneNumberExtractor {
  static final RegExp _candidate = RegExp(
    r'(?:(?:\+|00)\d{1,3}[\s\-\.]?)?(?:\(?\d{2,5}\)?[\s\-\.]?){1,4}\d{2,5}',
  );

  ExtractionResult extract(String input, {String defaultCountryCode = '+91'}) {
    if (input.trim().isEmpty) {
      return ExtractionResult(valid: [], rejected: [], duplicatesRemoved: 0, ambiguous: []);
    }

    final valid = <ExtractedNumber>[];
    final rejected = <RejectedCandidate>[];
    final ambiguous = <ExtractedNumber>[];
    final seen = <String>{};
    int duplicates = 0;

    // Process line by line to capture Name / Location context
    final lines = input.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Find numbers in this line
      for (final m in _candidate.allMatches(line)) {
        final raw = m.group(0)!.trim();
        if (RegExp(r'^\d{4}[\-/]\d{1,2}[\-/]\d{1,2}$').hasMatch(raw)) continue;

        final digits = raw.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 7 || digits.length > 15) continue;
        if (digits.length <= 6) continue;

        // Classify (same as your previous logic)
        String? normalized;
        String reason = '';

        if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
          normalized = '+91$digits';
        } else if (digits.length == 12 && digits.startsWith('91') && RegExp(r'^[6-9]\d{9}$').hasMatch(digits.substring(2))) {
          normalized = '+91${digits.substring(2)}';
        } else if (digits.length == 11 && digits.startsWith('0') && RegExp(r'^[6-9]\d{9}$').hasMatch(digits.substring(1))) {
          normalized = '+91${digits.substring(1)}';
        } else if (digits.startsWith('0') && digits.length >= 10 && digits.length <= 12) {
          reason = 'Landline number';
        } else if (digits.length >= 8 && digits.length <= 15) {
          // Treat as ambiguous international
          if (!seen.contains(raw)) {
            seen.add(raw);
            ambiguous.add(ExtractedNumber(raw, raw));
          }
          continue;
        } else {
          reason = 'Invalid mobile prefix';
        }

        if (normalized != null) {
          if (seen.contains(normalized)) {
            duplicates++;
          } else {
            seen.add(normalized);

            // --- Extract Context (Name, Location, Enquiry) ---
            // Remove the number from the line to see what's left
            String context = line.replaceFirst(raw, '').trim();
            context = context.replaceAll(RegExp(r'^[\s\-\:\,\.]+'), ''); // strip leading punctuation

            String? extractedName;
            String? extractedLocation;
            String? extractedEnquiry;

            if (context.isNotEmpty) {
              // If the line has commas, treat as Name, Location, Enquiry
              if (context.contains(',')) {
                final parts = context.split(',');
                extractedName = parts[0].trim();
                if (parts.length > 1) extractedLocation = parts[1].trim();
                if (parts.length > 2) extractedEnquiry = parts.sublist(2).join(',').trim();
              } else {
                // If no commas, just treat the text as the Name/Enquiry
                extractedName = context;
              }
            }

            valid.add(ExtractedNumber(
              normalized,
              raw,
              name: (extractedName?.isEmpty ?? true) ? null : extractedName,
              location: (extractedLocation?.isEmpty ?? true) ? null : extractedLocation,
              enquiry: (extractedEnquiry?.isEmpty ?? true) ? null : extractedEnquiry,
            ));
          }
        } else {
          rejected.add(RejectedCandidate(raw, reason));
        }
      }
    }

    return ExtractionResult(
      valid: valid,
      rejected: rejected,
      duplicatesRemoved: duplicates,
      ambiguous: ambiguous,
    );
  }
}