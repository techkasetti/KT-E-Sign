public class MLIntegrationUtils {
    public static Map<String,Object> parseAIResponse(HttpResponse res) {
        Map<String,Object> out = new Map<String,Object>{
            'success' => false,
            'raw' => res.getBody(),
            'data' => null
        };
        try {
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String,Object> body = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                out.put('success', true);
                out.put('data', body);
                // normalize known fields
                if (!body.containsKey('confidence') && body.containsKey('score')) {
                    out.put('confidence', body.get('score'));
                } else if (body.containsKey('confidence')) {
                    out.put('confidence', body.get('confidence'));
                }
            } else {
                out.put('error', 'HTTP ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception ex) {
            out.put('error', 'parse error: ' + ex.getMessage());
        }
        return out;
    }
}
