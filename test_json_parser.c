#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "yyjson.h"

int main(int argc, char *argv[]) {
    const char *filename = "test_response.json";
    if (argc > 1) {
        filename = argv[1];
    }
    
    // Read file
    FILE *fp = fopen(filename, "rb");
    if (!fp) {
        printf("Failed to open file: %s\n", filename);
        return 1;
    }
    
    fseek(fp, 0, SEEK_END);
    size_t file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    
    char *json_str = malloc(file_size + 1);
    fread(json_str, 1, file_size, fp);
    json_str[file_size] = '\0';
    fclose(fp);
    
    printf("Read %zu bytes from %s\n", file_size, filename);
    printf("JSON content:\n%s\n\n", json_str);
    
    // Parse with yyjson
    yyjson_read_err err;
    memset(&err, 0, sizeof(err));
    yyjson_doc *doc = yyjson_read_opts(json_str, file_size, 0, NULL, &err);
    
    if (!doc) {
        printf("Failed to parse JSON - Error code: %u, message: %s, position: %zu\n", 
               err.code, err.msg, err.pos);
        free(json_str);
        return 1;
    }
    
    printf("JSON parsed successfully!\n");
    
    // Get root
    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        printf("No root object\n");
        yyjson_doc_free(doc);
        free(json_str);
        return 1;
    }
    
    // Check for error message
    yyjson_val *error_msg = yyjson_obj_get(root, "message");
    if (error_msg && yyjson_is_str(error_msg)) {
        printf("Error message found: %s\n", yyjson_get_str(error_msg));
        yyjson_doc_free(doc);
        free(json_str);
        return 1;
    }
    
    // Get content array
    yyjson_val *content = yyjson_obj_get(root, "content");
    if (!content || !yyjson_is_arr(content)) {
        printf("No content array found\n");
        yyjson_doc_free(doc);
        free(json_str);
        return 1;
    }
    
    printf("Content array found with %zu items\n", yyjson_arr_size(content));
    
    // Get first content item
    yyjson_val *first_content = yyjson_arr_get(content, 0);
    if (!first_content) {
        printf("Content array is empty\n");
        yyjson_doc_free(doc);
        free(json_str);
        return 1;
    }
    
    // Get text field
    yyjson_val *text_val = yyjson_obj_get(first_content, "text");
    if (!text_val || !yyjson_is_str(text_val)) {
        printf("No text field in content item\n");
        yyjson_doc_free(doc);
        free(json_str);
        return 1;
    }
    
    const char *text = yyjson_get_str(text_val);
    printf("Extracted text: %s\n", text);
    
    // Clean up
    yyjson_doc_free(doc);
    free(json_str);
    
    return 0;
}