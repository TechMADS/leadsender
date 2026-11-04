import 'package:flutter_test/flutter_test.dart';
import 'package:leadsender/services/phone_number_extractor.dart';

void main() {
  final ex = PhoneNumberExtractor();

  test('single Indian mobile', () {
    final r = ex.extract('Call me on 9876543210');
    expect(r.valid.length, 1);
    expect(r.valid.first.normalized, '+919876543210');
  });

  test('multiple on separate lines', () {
    final r = ex.extract('9876543210\n9123456789\n');
    expect(r.valid.length, 2);
  });

  test('comma separated', () {
    final r = ex.extract('9876543210, 9123456789, 9988776655');
    expect(r.valid.length, 3);
  });

  test('+91 prefixed', () {
    final r = ex.extract('+91 9840123456');
    expect(r.valid.length, 1);
    expect(r.valid.first.normalized, '+919840123456');
  });

  test('spaces / parentheses / hyphens', () {
    final r = ex.extract('+91 98401-23456 and (984) 012-3456');
    expect(r.valid.length, 2);
  });

  test('duplicate removal', () {
    final r = ex.extract('9876543210\n9876543210\n+91 9876543210');
    expect(r.valid.length, 1);
    expect(r.duplicatesRemoved, 2);
  });

  test('dates are not numbers', () {
    final r = ex.extract('2024-01-01 9876543210');
    expect(r.valid.length, 1);
  });

  test('prices are not numbers', () {
    final r = ex.extract('Price 500 and 9876543210');
    expect(r.valid.length, 1);
  });

  test('invalid lengths rejected', () {
    final r = ex.extract('12345 and 12345678901234567890');
    expect(r.valid, isEmpty);
  });

  test('landline rejected', () {
    final r = ex.extract('(0413) 2234567');
    expect(r.valid, isEmpty);
    expect(r.rejected, isNotEmpty);
  });

  test('empty input', () {
    final r = ex.extract('');
    expect(r.valid, isEmpty);
    expect(r.rejected, isEmpty);
  });

  test('no numbers', () {
    final r = ex.extract('Hello, no leads today.');
    expect(r.valid, isEmpty);
  });

  test('unicode digits', () {
    // Arabic-Indic digits for 9876543210
    final r = ex.extract('٩٨٧٦٥٤٣٢١٠');
    expect(r.valid.length, 1);
    expect(r.valid.first.normalized, '+919876543210');
  });

  test('ambiguous international shown', () {
    final r = ex.extract('+1 415 555 0123');
    expect(r.ambiguous, isNotEmpty);
    expect(r.valid, isEmpty);
  });
}