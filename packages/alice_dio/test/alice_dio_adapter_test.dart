import 'dart:io';

import 'package:alice/core/alice_core.dart';
import 'package:alice/model/alice_form_data_file.dart';
import 'package:alice/model/alice_from_data_field.dart';
import 'package:alice/model/alice_http_call.dart';
import 'package:alice/model/alice_http_response.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:alice_test/alice_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' as http_mock_adapter;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'alice_core_mock.dart';

void main() {
  late AliceCore aliceCore;
  late AliceDioAdapter aliceDioAdapter;
  late Dio dio;
  late http_mock_adapter.DioAdapter dioAdapter;
  setUp(() {
    registerFallbackValue(AliceHttpCall(0));
    registerFallbackValue(AliceHttpResponse());

    aliceCore = AliceCoreMock();
    when(() => aliceCore.addCall(any())).thenAnswer((_) => {});
    when(() => aliceCore.addResponse(any(), any())).thenAnswer((_) => {});

    aliceDioAdapter = AliceDioAdapter();
    aliceDioAdapter.injectCore(aliceCore);

    dio = Dio(BaseOptions(followRedirects: false))
      ..interceptors.add(aliceDioAdapter);
    dioAdapter = http_mock_adapter.DioAdapter(dio: dio);
  });

  group("AliceDioAdapter", () {
    test("should handle GET call with json response", () async {
      dioAdapter.onGet(
        'https://test.com/json',
        (server) => server.reply(
          200,
          '{"result": "ok"}',
          headers: {
            "content-type": ["application/json"]
          },
        ),
        headers: {"content-type": "application/json"},
      );

      await dio.get<void>(
        'https://test.com/json',
        options: Options(
          headers: {"content-type": "application/json"},
        ),
      );

      final requestMatcher = buildRequestMatcher(
        checkTime: true,
        headers: {"content-type": "application/json"},
        contentType: "application/json",
        queryParameters: {},
      );

      final responseMatcher = buildResponseMatcher(checkTime: true);

      final callMatcher = buildCallMatcher(
          checkId: true,
          checkTime: true,
          secured: true,
          loading: true,
          client: 'Dio',
          method: 'GET',
          endpoint: '/json',
          server: 'test.com',
          uri: 'https://test.com/json',
          duration: 0,
          request: requestMatcher,
          response: responseMatcher);

      verify(() => aliceCore.addCall(any(that: callMatcher)));

      final nextResponseMatcher = buildResponseMatcher(
        status: 200,
        size: 16,
        checkTime: true,
        body: '{"result": "ok"}',
        headers: {'content-type': '[application/json]'},
      );

      verify(
          () => aliceCore.addResponse(any(that: nextResponseMatcher), any()));
    });

    test("should handle POST call with json response", () async {
      dioAdapter.onPost(
          'https://test.com/json',
          (server) => server.reply(
                200,
                '{"result": "ok"}',
                headers: {
                  "content-type": ["application/json"]
                },
              ),
          data: '{"data":"test"}',
          headers: {"content-type": "application/json"},
          queryParameters: {"sort": "asc"});

      await dio.post<void>(
        'https://test.com/json',
        data: '{"data":"test"}',
        queryParameters: {"sort": "asc"},
        options: Options(
          headers: {"content-type": "application/json"},
        ),
      );

      final requestMatcher = buildRequestMatcher(
        checkTime: true,
        headers: {"content-type": "application/json"},
        contentType: "application/json",
        body: '{"data":"test"}',
        queryParameters: {"sort": "asc"},
      );

      final responseMatcher = buildResponseMatcher(checkTime: true);

      final callMatcher = buildCallMatcher(
          checkId: true,
          checkTime: true,
          secured: true,
          loading: true,
          client: 'Dio',
          method: 'POST',
          endpoint: '/json',
          server: 'test.com',
          uri: 'https://test.com/json?sort=asc',
          duration: 0,
          request: requestMatcher,
          response: responseMatcher);

      verify(() => aliceCore.addCall(any(that: callMatcher)));

      final nextResponseMatcher = buildResponseMatcher(
        status: 200,
        size: 16,
        checkTime: true,
        body: '{"result": "ok"}',
        headers: {'content-type': '[application/json]'},
      );

      verify(
          () => aliceCore.addResponse(any(that: nextResponseMatcher), any()));
    });

    test("should handle form data", () async {
      final file = File("image.png");
      file.createSync();

      var formData = FormData.fromMap({
        'name': 'Alice',
        'surname': 'test',
        'image': MultipartFile.fromFileSync(file.path)
      });

      dioAdapter.onPost(
          'https://test.com/form',
          (server) => server.reply(
                200,
                '{"result": "ok"}',
              ),
          data: formData);

      await dio.post<void>(
        'https://test.com/form',
        data: formData,
      );

      final requestMatcher = buildRequestMatcher(
          checkTime: true,
          formDataFields: [
            const AliceFormDataField('name', 'Alice'),
            const AliceFormDataField('surname', 'test'),
          ],
          formDataFiles: [
            const AliceFormDataFile("image.png", "application/octet-stream", 0),
          ],
          body: 'Form data',
          headers: {'content-type': 'multipart/form-data'});
      final responseMatcher = buildResponseMatcher(checkTime: true);

      final callMatcher = buildCallMatcher(
          checkId: true,
          checkTime: true,
          secured: true,
          loading: true,
          client: 'Dio',
          method: 'POST',
          endpoint: '/form',
          server: 'test.com',
          uri: 'https://test.com/form',
          duration: 0,
          request: requestMatcher,
          response: responseMatcher);

      verify(() => aliceCore.addCall(any(that: callMatcher)));

      final nextResponseMatcher = buildResponseMatcher(
        status: 200,
        size: 16,
        checkTime: true,
        body: '{"result": "ok"}',
        headers: {'content-type': '[application/json]'},
      );

      verify(
          () => aliceCore.addResponse(any(that: nextResponseMatcher), any()));
      file.deleteSync();
    });
  });
}
