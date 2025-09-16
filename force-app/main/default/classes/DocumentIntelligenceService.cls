public class DocumentIntelligenceService {
    
    private static final String AI_ENDPOINT = 'callout:Document_AI_Service';
    
    /**
     * Extract structured data from document content
     */
    @AuraEnabled
    public static DocumentExtractionResult extractDocumentData(String documentId) {
        try {
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, DocumentContent__c, ContractType__c, DocumentTitle__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            // Call AI service for document extraction
            Map<String, Object> extractionRequest = new Map<String, Object>();
            extractionRequest.put('content', document.DocumentContent__c);
            extractionRequest.put('documentType', document.ContractType__c);
            extractionRequest.put('extractionTypes', new List<String>{'entities', 'dates', 'amounts', 'signatures'});
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(AI_ENDPOINT + '/extract');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer {!$Credential.Document_AI.AccessToken}');
            request.setBody(JSON.serialize(extractionRequest));
            request.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            DocumentExtractionResult result = new DocumentExtractionResult();
            result.documentId = documentId;
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> aiResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                result.extractedEntities = (List<Object>)aiResponse.get('entities');
                result.extractedDates = (List<Object>)aiResponse.get('dates');
                result.extractedAmounts = (List<Object>)aiResponse.get('amounts');
                result.keyPhrases = (List<String>)aiResponse.get('keyPhrases');
                result.confidence = (Decimal)aiResponse.get('confidence');
                result.documentSummary = (String)aiResponse.get('summary');
                result.success = true;
                
                // Store extraction results
                storeExtractionResults(documentId, result);
                
            } else {
                result.success = false;
                result.errorMessage = 'Document extraction failed: ' + response.getBody();
            }
            
            return result;
            
        } catch (Exception e) {
            DocumentExtractionResult errorResult = new DocumentExtractionResult();
            errorResult.success = false;
            errorResult.errorMessage = 'Document intelligence service error: ' + e.getMessage();
            return errorResult;
        }
    }
    
    /**
     * Analyze document complexity and readability
     */
    @AuraEnabled
    public static DocumentAnalysisResult analyzeDocumentComplexity(String documentId) {
        try {
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, DocumentContent__c, ContractType__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            DocumentAnalysisResult analysis = new DocumentAnalysisResult();
            analysis.documentId = documentId;
            
            // Calculate basic metrics
            String content = document.DocumentContent__c;
            analysis.wordCount = content.split('\\s+').size();
            analysis.sentenceCount = content.split('[.!?]+').size();
            analysis.paragraphCount = content.split('\n\n').size();
            analysis.averageWordsPerSentence = analysis.wordCount / Math.max(analysis.sentenceCount, 1);
            
            // Calculate readability scores
            analysis.fleschReadingEase = calculateFleschReadingEase(content);
            analysis.fleschKincaidGrade = calculateFleschKincaidGrade(content);
            
            // Complexity assessment
            if (analysis.fleschReadingEase >= 90) {
                analysis.complexityLevel = 'Very Easy';
            } else if (analysis.fleschReadingEase >= 80) {
                analysis.complexityLevel = 'Easy';
            } else if (analysis.fleschReadingEase >= 70) {
                analysis.complexityLevel = 'Fairly Easy';
            } else if (analysis.fleschReadingEase >= 60) {
                analysis.complexityLevel = 'Standard';
            } else if (analysis.fleschReadingEase >= 50) {
                analysis.complexityLevel = 'Fairly Difficult';
            } else if (analysis.fleschReadingEase >= 30) {
                analysis.complexityLevel = 'Difficult';
            } else {
                analysis.complexityLevel = 'Very Difficult';
            }
            
            // Generate recommendations
            analysis.recommendations = generateComplexityRecommendations(analysis);
            analysis.success = true;
            
            return analysis;
            
        } catch (Exception e) {
            DocumentAnalysisResult errorResult = new DocumentAnalysisResult();
            errorResult.success = false;
            errorResult.errorMessage = 'Document analysis error: ' + e.getMessage();
            return errorResult;
        }
    }
    
    /**
     * Generate document improvement suggestions using AI
     */
    @AuraEnabled
    public static DocumentImprovementResult generateImprovementSuggestions(String documentId) {
        try {
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, DocumentContent__c, ContractType__c, Region__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            Map<String, Object> improvementRequest = new Map<String, Object>();
            improvementRequest.put('content', document.DocumentContent__c);
            improvementRequest.put('documentType', document.ContractType__c);
            improvementRequest.put('region', document.Region__c);
            improvementRequest.put('improvementAreas', new List<String>{
                'clarity', 'legal_compliance', 'structure', 'language'
            });
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(AI_ENDPOINT + '/improve');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer {!$Credential.Document_AI.AccessToken}');
            request.setBody(JSON.serialize(improvementRequest));
            request.setTimeout(45000);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            DocumentImprovementResult result = new DocumentImprovementResult();
            result.documentId = documentId;
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> aiResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                result.improvementSuggestions = (List<Object>)aiResponse.get('suggestions');
                result.prioritizedChanges = (List<Object>)aiResponse.get('prioritizedChanges');
                result.estimatedImpactScore = (Decimal)aiResponse.get('impactScore');
                result.overallRating = (String)aiResponse.get('overallRating');
                result.confidence = (Decimal)aiResponse.get('confidence');
                result.success = true;
                
            } else {
                result.success = false;
                result.errorMessage = 'Improvement analysis failed: ' + response.getBody();
            }
            
            return result;
            
        } catch (Exception e) {
            DocumentImprovementResult errorResult = new DocumentImprovementResult();
            errorResult.success = false;
            errorResult.errorMessage = 'Document improvement service error: ' + e.getMessage();
            return errorResult;
        }
    }
    
    // Helper methods
    private static void storeExtractionResults(String documentId, DocumentExtractionResult result) {
        try {
            Document_Extraction_Result__c extraction = new Document_Extraction_Result__c();
            extraction.Document_Id__c = documentId;
            extraction.Extracted_Entities__c = JSON.serialize(result.extractedEntities);
            extraction.Extracted_Dates__c = JSON.serialize(result.extractedDates);
            extraction.Extracted_Amounts__c = JSON.serialize(result.extractedAmounts);
            extraction.Key_Phrases__c = String.join(result.keyPhrases, '; ');
            extraction.Confidence_Score__c = result.confidence;
            extraction.Document_Summary__c = result.documentSummary;
            extraction.Extraction_Date__c = System.now();
            
            insert extraction;
        } catch (Exception e) {
            System.debug('Failed to store extraction results: ' + e.getMessage());
} catch (Exception e) {
    
}
}

private static Decimal calculateFleschReadingEase(String content) {
    try {
        // Remove HTML tags and clean content
        String cleanContent = content.replaceAll('<[^>]+>', '').trim();
        
        // Count sentences, words, and syllables
        Integer sentences = cleanContent.split('[.!?]+').size();
        List<String> words = cleanContent.split('\\s+');
        Integer wordCount = words.size();
        Integer syllableCount = 0;
        
        for (String word : words) {
            syllableCount += countSyllables(word.toLowerCase().replaceAll('[^a-z]', ''));
        }
        
        if (sentences > 0 && wordCount > 0) {
            // Flesch Reading Ease formula: 206.835 - (1.015 × ASL) - (84.6 × ASW)
            Decimal asl = (Decimal) wordCount / sentences;
            Decimal asw = (Decimal) syllableCount / wordCount;
            return 206.835 - (1.015 * asl) - (84.6 * asw);
        }
        
        return 50.0; // Default neutral score
    } catch (Exception e) {
        System.debug('Flesch Reading Ease calculation error: ' + e.getMessage());
        return 50.0;
    }
}

private static Decimal calculateFleschKincaidGrade(String content) {
    try {
        String cleanContent = content.replaceAll('<[^>]+>', '').trim();
        
        Integer sentences = cleanContent.split('[.!?]+').size();
        List<String> words = cleanContent.split('\\s+');
        Integer wordCount = words.size();
        Integer syllableCount = 0;
        
        for (String word : words) {
            syllableCount += countSyllables(word.toLowerCase().replaceAll('[^a-z]', ''));
        }
        
        if (sentences > 0 && wordCount > 0) {
            // Flesch-Kincaid Grade Level: (0.39 × ASL) + (11.8 × ASW) - 15.59
            Decimal asl = (Decimal) wordCount / sentences;
            Decimal asw = (Decimal) syllableCount / wordCount;
            return (0.39 * asl) + (11.8 * asw) - 15.59;
        }
        
        return 12.0; // Default 12th grade level
    } catch (Exception e) {
        System.debug('Flesch-Kincaid Grade calculation error: ' + e.getMessage());
        return 12.0;
    }
}

private static Integer countSyllables(String word) {
    if (String.isEmpty(word)) return 1;
    
    word = word.toLowerCase();
    Integer syllables = 0;
    Boolean previousWasVowel = false;
    
    // Count vowel groups
    for (Integer i = 0; i < word.length(); i++) {
        String character = word.substring(i, i + 1);
        Boolean isVowel = 'aeiou'.contains(character);
        
        if (isVowel && !previousWasVowel) {
            syllables++;
        }
        previousWasVowel = isVowel;
    }
    
    // Handle silent 'e'
    if (word.endsWith('e') && syllables > 1) {
        syllables--;
    }
    
    return Math.max(syllables, 1); // Every word has at least one syllable
}

private static List<String> generateComplexityRecommendations(DocumentAnalysisResult analysis) {
    List<String> recommendations = new List<String>();
    
    if (analysis.averageWordsPerSentence > 20) {
        recommendations.add(
            'Consider breaking down long sentences (current average: ' + 
            analysis.averageWordsPerSentence + ' words per sentence)'
        );
    }
    
    if (analysis.fleschReadingEase < 60) {
        recommendations.add(
            'Simplify language to improve readability (current score: ' + 
            analysis.fleschReadingEase.setScale(1) + ')'
        );
    }
    
    if (analysis.fleschKincaidGrade > 12) {
        recommendations.add(
            'Reduce complexity - current reading level requires ' + 
            analysis.fleschKincaidGrade.setScale(1) + ' years of education'
        );
    }
    
    if (analysis.wordCount > 2000) {
        recommendations.add(
            'Consider condensing content - document length may impact completion rates'
        );
    }
    
    if (recommendations.isEmpty()) {
        recommendations.add('Document complexity is within acceptable ranges for most users');
    }
    
    return recommendations;
}
public class DocumentExtractionResult {
    
    @AuraEnabled public String documentId { get; set; }
    @AuraEnabled public List<Object> extractedEntities { get; set; }
    @AuraEnabled public List<Object> extractedDates { get; set; }
    @AuraEnabled public List<Object> extractedAmounts { get; set; }
    @AuraEnabled public List<String> keyPhrases { get; set; }
    @AuraEnabled public String documentSummary { get; set; }
    @AuraEnabled public Decimal confidence { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

    // Constructor
    public DocumentExtractionResult() {
        this.extractedEntities = new List<Object>();
        this.extractedDates = new List<Object>();
        this.extractedAmounts = new List<Object>();
        this.keyPhrases = new List<String>();
        this.confidence = 0.0;
        this.success = false;
    }
}

public class DocumentAnalysisResult {

    @AuraEnabled public String documentId { get; set; }
    @AuraEnabled public Integer wordCount { get; set; }
    @AuraEnabled public Integer sentenceCount { get; set; }
    @AuraEnabled public Integer paragraphCount { get; set; }
    @AuraEnabled public Decimal averageWordsPerSentence { get; set; }
    @AuraEnabled public Decimal fleschReadingEase { get; set; }
    @AuraEnabled public Decimal fleschKincaidGrade { get; set; }
    @AuraEnabled public String complexityLevel { get; set; }
    @AuraEnabled public List<String> recommendations { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

    // Constructor
    public DocumentAnalysisResult() {
        this.recommendations = new List<String>();
        this.success = false;
    }
}


public class DocumentImprovementResult {
    
    @AuraEnabled public String documentId { get; set; }
    @AuraEnabled public List<Object> improvementSuggestions { get; set; }
    @AuraEnabled public List<Object> prioritizedChanges { get; set; }
    @AuraEnabled public Decimal estimatedImpactScore { get; set; }
    @AuraEnabled public String overallRating { get; set; }
    @AuraEnabled public Decimal confidence { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

    // Constructor
    public DocumentImprovementResult() {
        this.improvementSuggestions = new List<Object>();
        this.prioritizedChanges = new List<Object>();
        this.success = false;
    }
}

    @AuraEnabled
    public static SignatureFieldDetectionResult detectSignatureFields(Id documentId) {
        try {
            // Get document content
            ContentVersion document = [
                SELECT Id, VersionData, FileExtension
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId AND IsLatest = true
            ];
            
            // Convert to base64 for AI processing
            String documentContent = EncodingUtil.base64Encode(document.VersionData);
            
            // Call AI service for field detection
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:DocumentAI/detect-fields');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> aiRequest = new Map<String, Object>{
                'document' => documentContent,
                'document_type' => document.FileExtension,
                'detection_types' => new List<String>{'signature', 'date', 'initial', 'checkbox'}
            };
            
            request.setBody(JSON.serialize(aiRequest));
            request.setTimeout(60000);
            
            HttpResponse response = http.send(request);
            Map<String, Object> aiResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            // Process detected fields
            List<Object> detectedFields = (List<Object>) aiResponse.get('fields');
            List<SignatureField> signatureFields = new List<SignatureField>();
            
            for (Object fieldObj : detectedFields) {
                Map<String, Object> field = (Map<String, Object>) fieldObj;
                
                SignatureField sigField = new SignatureField();
                sigField.fieldType = (String) field.get('type');
                sigField.confidence = (Decimal) field.get('confidence');
                sigField.coordinates = parseCoordinates((Map<String, Object>) field.get('coordinates'));
                sigField.required = (Boolean) field.get('required');
                
                signatureFields.add(sigField);
            }
            
            // Store detection results
            Document_Intelligence_Result__c result = new Document_Intelligence_Result__c();
            result.Document_Id__c = documentId;
            result.Fields_Detected__c = signatureFields.size();
            result.Detection_Confidence__c = (Decimal) aiResponse.get('overall_confidence');
            result.AI_Response__c = JSON.serialize(aiResponse);
            result.Processing_Date__c = System.now();
            insert result;
            
            return new SignatureFieldDetectionResult(true, signatureFields, 'Fields detected successfully');
            
        } catch (Exception e) {
            System.debug('Document intelligence error: ' + e.getMessage());
            return new SignatureFieldDetectionResult(false, null, 'Error detecting fields: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static DocumentClassificationResult classifyDocument(Id documentId) {
        try {
            ContentVersion document = [
                SELECT Id, VersionData, Title
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId AND IsLatest = true
            ];
            
            // Extract text content for classification
            String textContent = extractTextContent(document.VersionData);
            
           


// Call AI classification service
Http http = new Http();
HttpRequest request = new HttpRequest();
request.setEndpoint('callout:DocumentAI/classify');
request.setMethod('POST');
request.setHeader('Content-Type', 'application/json');
request.setHeader('Authorization', 'Bearer {!$Credential.DocumentAI.AccessToken}');

Map<String, Object> classificationRequest = new Map<String, Object>{
    'content' => textContent,
    'document_title' => document.Title,
    'classification_models' => new List<String>{
        'contract_type',
        'legal_document',
        'compliance_level',
        'language_detection',
        'complexity_analysis'
    }
};

request.setBody(JSON.serialize(classificationRequest));
request.setTimeout(45000);

HttpResponse response = http.send(request);
Map<String, Object> classificationResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

// Process classification results
DocumentClassificationResult result = new DocumentClassificationResult();
result.documentType = (String) classificationResponse.get('primary_type');
result.confidence = (Decimal) classificationResponse.get('confidence');
result.language = (String) classificationResponse.get('detected_language');
result.complexity = (String) classificationResponse.get('complexity_level');
result.complianceRequirements = (List<String>) classificationResponse.get('compliance_requirements');

// Store classification
Document_Classification__c classification = new Document_Classification__c();
classification.Document_Id__c = documentId;
classification.Document_Type__c = result.documentType;
classification.Confidence_Score__c = result.confidence;
classification.Language__c = result.language;
classification.Complexity_Level__c = result.complexity;
classification.Compliance_Requirements__c = String.join(result.complianceRequirements, ';');
classification.Classification_Date__c = System.now();
insert classification;

return result;

} catch (Exception e) {
    System.debug('Document classification error: ' + e.getMessage());
    return new DocumentClassificationResult('ERROR', 0, 'Error classifying document: ' + e.getMessage());
}
}

private static String extractTextContent(Blob documentData) {
    // OCR integration for text extraction
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:OCR_Service/extract-text');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    
    Map<String, Object> ocrRequest = new Map<String, Object>{
        'document' => EncodingUtil.base64Encode(documentData),
        'output_format' => 'text',
        'language' => 'auto-detect'
    };
    
    request.setBody(JSON.serialize(ocrRequest));
    HttpResponse response = http.send(request);
    
    Map<String, Object> ocrResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    return (String) ocrResponse.get('extracted_text');
}

} 

