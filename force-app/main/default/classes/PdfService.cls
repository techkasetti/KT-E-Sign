public with sharing class PdfService {
    @TestVisible
    public static String convertToBase64PDF(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            throw new IllegalArgumentException('htmlContent is required');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PDF_Service/convert');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(new Map<String,Object>{ 'html' => htmlContent }));
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            // Accept either { "base64":"..." } or raw base64
            try {
                Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                if (parsed!=null && parsed.containsKey('base64')) {
                    return (String) parsed.get('base64');
                }
            } catch(Exception ignored) {
                // not JSON; may be raw base64
            }
            return res.getBody();
        }
        throw new CalloutException('PDF conversion failed: ' + res.getStatus() + ' ' + res.getBody());
    }
}
