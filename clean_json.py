#!/usr/bin/env python3
import json
import re

def clean_json_file(input_file, output_file):
    """
    Remove all 'expert_summary' fields from JSON file and fix formatting issues.
    """
    print(f"Reading file: {input_file}")
    
    # Read the entire file as text
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"Original file size: {len(content)} characters")
    
    # First, let's try to fix basic JSON formatting issues
    # Replace unescaped newlines in string values with escaped newlines
    # This regex finds strings and replaces unescaped newlines within them
    def fix_newlines_in_strings(text):
        # This is a complex operation, so we'll use a different approach
        # Let's work with the structure we know exists
        return text
    
    # Remove expert_summary fields using regex
    # Pattern matches: "expert_summary": "content", (with proper handling of nested quotes and newlines)
    
    # This pattern will match the expert_summary field and its content
    # We need to be careful about nested quotes and newlines
    pattern = r'"expert_summary"\s*:\s*"[^"]*(?:\\.[^"]*)*"\s*,?\s*'
    
    # However, given the complexity of the content, let's use a more robust approach
    # We'll parse this manually by finding the expert_summary field and its closing quote
    
    def remove_expert_summary_fields(text):
        result = []
        lines = text.split('\n')
        
        skip_lines = False
        bracket_count = 0
        in_expert_summary = False
        expert_summary_start = False
        
        for i, line in enumerate(lines):
            stripped = line.strip()
            
            # Check if this line starts an expert_summary field
            if '"expert_summary"' in line and ':' in line:
                in_expert_summary = True
                expert_summary_start = True
                # Don't add this line to result
                continue
            
            if in_expert_summary:
                # Count quotes to find the end of the string value
                if expert_summary_start:
                    # Find the opening quote after the colon
                    colon_pos = line.find(':')
                    if colon_pos != -1:
                        quote_pos = line.find('"', colon_pos)
                        if quote_pos != -1:
                            # Start counting from after the opening quote
                            line_part = line[quote_pos + 1:]
                        else:
                            line_part = line
                    else:
                        line_part = line
                    expert_summary_start = False
                else:
                    line_part = line
                
                # Count unescaped quotes
                escaped = False
                quote_count = 0
                for char in line_part:
                    if escaped:
                        escaped = False
                        continue
                    if char == '\\':
                        escaped = True
                        continue
                    if char == '"':
                        quote_count += 1
                
                # If we have an odd number of quotes, we've reached the end of the string
                if quote_count % 2 == 1:
                    in_expert_summary = False
                    # Check if there's a comma after the closing quote
                    closing_quote_pos = line_part.rfind('"')
                    if closing_quote_pos != -1:
                        after_quote = line_part[closing_quote_pos + 1:].strip()
                        if after_quote.startswith(','):
                            # Remove the comma too
                            pass
                # Don't add this line to result
                continue
            
            # Add the line to result if we're not in expert_summary
            result.append(line)
        
        return '\n'.join(result)
    
    # Apply the removal
    print("Removing expert_summary fields...")
    cleaned_content = remove_expert_summary_fields(content)
    
    # Now let's try to parse and reformat as proper JSON
    print("Parsing and reformatting JSON...")
    try:
        # Try to parse the cleaned content
        data = json.loads(cleaned_content)
        
        # Double-check: remove any remaining expert_summary fields
        for item in data:
            if 'expert_summary' in item:
                del item['expert_summary']
        
        # Format as proper JSON with indentation
        formatted_json = json.dumps(data, indent=2, ensure_ascii=False)
        
        print(f"Successfully parsed {len(data)} entries")
        print(f"Cleaned file size: {len(formatted_json)} characters")
        
        # Write the cleaned file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(formatted_json)
        
        print(f"File saved to: {output_file}")
        
        # Verify no expert_summary fields remain
        remaining_expert_summaries = formatted_json.count('"expert_summary"')
        if remaining_expert_summaries == 0:
            print("✓ All expert_summary fields successfully removed")
        else:
            print(f"⚠ Warning: {remaining_expert_summaries} expert_summary fields still remain")
            
        return True
        
    except json.JSONDecodeError as e:
        print(f"JSON parsing error: {e}")
        print("Attempting alternative approach...")
        
        # Fallback: write the cleaned content and let user know manual review needed
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(cleaned_content)
        
        print(f"Cleaned content saved to: {output_file}")
        print("Note: Manual review may be needed for final formatting")
        return False

if __name__ == "__main__":
    input_file = "/Users/reidsterling/Desktop/Synagamy/Synagamy3.0/Data/JSON/Education_Topics.json"
    output_file = "/Users/reidsterling/Desktop/Synagamy/Synagamy3.0/Data/JSON/Education_Topics.json"
    
    # Create a backup first
    backup_file = input_file + ".backup"
    print(f"Creating backup at: {backup_file}")
    
    with open(input_file, 'r', encoding='utf-8') as src, open(backup_file, 'w', encoding='utf-8') as dst:
        dst.write(src.read())
    
    print("Backup created successfully")
    
    # Clean the file
    success = clean_json_file(input_file, output_file)
    
    if success:
        print("\n✓ Operation completed successfully!")
    else:
        print("\n⚠ Operation completed with warnings - please review the output file")