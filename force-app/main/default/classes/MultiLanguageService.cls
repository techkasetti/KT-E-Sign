public with sharing class MultiLanguageService {
        @AuraEnabled
    public static LanguageSupportResult enableMultiLanguageSupport(Id documentId, String targetLanguage) {
        try {
            // Get document content
            ContentVersion document = [
                SELECT Id, VersionData, Title, Language__c 
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true
            ];
            
            String sourceContent = extractTextContent(document.VersionData);
            
            // Call translation service
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:TranslationService/translate');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> translationRequest = new Map<String, Object>{
                'source_text' => sourceContent,
                'source_language' => document.Language__c,
                'target_language' => targetLanguage,
                'preserve_formatting' => true,
                'legal_domain' => true
            };
            
            request.setBody(JSON.serialize(translationRequest));
            HttpResponse response = http.send(request);
            
            Map<String, Object> translationResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            // Create translated version
            String translatedContent = (String) translationResponse.get('translated_text');
            Decimal confidenceScore = (Decimal) translationResponse.get('confidence');
            
            // Generate localized compliance clauses
            String localizedClauses = generateLocalizedClauses(targetLanguage);
            
            // Create new document version with translation
            Document_Translation__c translation = new Document_Translation__c();
            translation.Original_Document__c = documentId;
            translation.Target_Language__c = targetLanguage;
            translation.Translated_Content__c = translatedContent;
            translation.Translation_Confidence__c = confidenceScore;
            translation.Localized_Clauses__c = localizedClauses;
            translation.Translation_Date__c = System.now();
            insert translation;
            
            return new LanguageSupportResult(true, translatedContent, confidenceScore, 'Translation completed successfully');
            
        } catch (Exception e) {
            System.debug('Multi-language support error: ' + e.getMessage());
            return new LanguageSupportResult(false, null, 0, 'Translation error: ' + e.getMessage());
        }
    }
    
    private static String generateLocalizedClauses(String language) {
        Map<String, String> localizedClauses = new Map<String, String>();
        
        // Define localized legal clauses for different languages
        switch on language {
            when 'es' {
                localizedClauses.put('consent', 'Al firmar electrónicamente este documento, usted acepta que su firma electrónica tiene la misma validez legal que una firma manuscrita.');
                localizedClauses.put('gdpr', 'Sus datos personales serán procesados de acuerdo con el Reglamento General de Protección de Datos (GDPR).');
            }
            when 'fr' {
                localizedClauses.put('consent', 'En signant électroniquement ce document, vous acceptez que votre signature électronique ait la même validité légale qu\'une signature manuscrite.');
                localizedClauses.put('gdpr', 'Vos données personnelles seront traitées conformément au Règlement Général sur la Protection des Données (RGPD).');
            }
            when 'de' {
                localizedClauses.put('consent', 'Durch die elektronische Unterzeichnung dieses Dokuments stimmen Sie zu, dass Ihre elektronische Signatur die gleiche rechtliche Gültigkeit hat wie eine handschriftliche Unterschrift.');
                localizedClauses.put('gdpr', 'Ihre personenbezogenen Daten werden gemäß der Datenschutz-Grundverordnung (DSGVO) verarbeitet.');
            }
            when else {
                localizedClauses.put('consent', 'By electronically signing this document, you agree that your electronic signature has the same legal validity as a handwritten signature.');
                localizedClauses.put('gdpr', 'Your personal data will be processed in accordance with the General Data Protection Regulation (GDPR).');
            }
        }
        
        return JSON.serialize(localizedClauses);
    }
}
 
