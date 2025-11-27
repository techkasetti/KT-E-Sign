public class MLIntegrationUtils {
      public static Map<String,Object> parseAIResponse(HttpResponse res) {
        Map<String,Object> out = new Map<String,Object>{
            'success' => false,
            'raw' => null,
            'data' => null,
            'confidence' => null,
            'error' => null
        };
        try {
            out.put('raw', res.getBody());
            Integer status = res.getStatusCode();
            if (status >= 200 && status < 300) {
                // try to parse JSON into map or list
                try {
                    Object decoded = JSON.deserializeUntyped(res.getBody());
                    out.put('data', decoded);
                    out.put('success', true);
                    // detect common confidence keys
                    if (decoded instanceof Map<String,Object>) {
                        Map<String,Object> m = (Map<String,Object>) decoded;
                        if (m.containsKey('confidence')) out.put('confidence', m.get('confidence'));
                        else if (m.containsKey('score')) out.put('confidence', m.get('score'));
                        else if (m.containsKey('prediction_confidence')) out.put('confidence', m.get('prediction_confidence'));
                    }
                } catch (Exception e1) {
                    // Not valid JSON - keep raw text; caller may want to run fallback parsing
                    out.put('data', res.getBody());
                    out.put('success', true);
                }
            } else {
                out.put('error', 'HTTP ' + status + ' : ' + res.getBody());
            }
        } catch (Exception e) {
            out.put('error', 'parse error: ' + e.getMessage());
        }
        return out;
    }
}