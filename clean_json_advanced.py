#!/usr/bin/env python3
import json
import re

def clean_json_file(input_file, output_file):
    """
    Remove all 'expert_summary' fields from JSON file and fix formatting issues.
    Uses a more robust approach to handle complex string content.
    """
    print(f"Reading file: {input_file}")
    
    # Read the entire file as text
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"Original file size: {len(content)} characters")
    
    # First approach: try to use a regex that properly handles the expert_summary field
    # This regex handles multi-line strings with escaped quotes
    def remove_expert_summary_regex(text):
        # Pattern explanation:
        # "expert_summary"\s*:\s* - matches the field name with optional whitespace
        # " - matches opening quote
        # (?:[^"\\]|\\.)* - matches any character except quote/backslash, or escaped characters
        # " - matches closing quote  
        # \s*,?\s* - matches optional comma and whitespace after
        pattern = r'"expert_summary"\s*:\s*"(?:[^"\\]|\\.)*"\s*,?\s*'
        
        # However, this might not work with multiline strings that have unescaped newlines
        # Let's try a different approach
        
        # Split into lines and process line by line
        lines = text.split('\n')
        result_lines = []
        in_expert_summary = False
        quote_count = 0
        
        for line in lines:
            if not in_expert_summary:
                # Check if this line contains the start of expert_summary
                if '"expert_summary"' in line and ':' in line:
                    in_expert_summary = True
                    # Count quotes in this line to see if the field ends here too
                    colon_pos = line.find('"expert_summary"')
                    colon_actual = line.find(':', colon_pos)
                    if colon_actual != -1:
                        after_colon = line[colon_actual + 1:]
                        # Find the opening quote
                        first_quote = after_colon.find('"')
                        if first_quote != -1:
                            # Count quotes after the first quote
                            content_part = after_colon[first_quote + 1:]
                            escaped = False
                            quotes_found = 0
                            
                            for i, char in enumerate(content_part):
                                if escaped:
                                    escaped = False
                                    continue
                                if char == '\\':
                                    escaped = True
                                    continue
                                if char == '"':
                                    quotes_found += 1
                                    # If we found the closing quote
                                    if quotes_found == 1:
                                        # Check what comes after
                                        remaining = content_part[i + 1:].strip()
                                        if remaining.startswith(','):
                                            # This line ends the expert_summary field
                                            in_expert_summary = False
                                        break
                            
                            if quotes_found == 0:
                                # The string continues to next lines
                                pass
                            elif quotes_found == 1:
                                # The string ends in this line
                                in_expert_summary = False
                    
                    # Don't include this line
                    continue
                else:
                    # Normal line, include it
                    result_lines.append(line)
            else:
                # We're inside expert_summary, look for the closing quote
                escaped = False
                for i, char in enumerate(line):
                    if escaped:
                        escaped = False
                        continue
                    if char == '\\':
                        escaped = True
                        continue
                    if char == '"':
                        # Found closing quote
                        remaining = line[i + 1:].strip()
                        if remaining.startswith(','):
                            # Remove the comma too
                            pass
                        in_expert_summary = False
                        break
                
                # Don't include this line
                continue
        
        return '\n'.join(result_lines)
    
    # Apply the removal
    print("Removing expert_summary fields...")
    cleaned_content = remove_expert_summary_regex(content)
    
    # Try to fix any remaining JSON formatting issues
    print("Attempting to parse and reformat JSON...")
    
    try:
        # Parse the JSON
        data = json.loads(cleaned_content)
        
        # Double-check: remove any remaining expert_summary fields
        removed_count = 0
        for item in data:
            if 'expert_summary' in item:
                del item['expert_summary']
                removed_count += 1
        
        if removed_count > 0:
            print(f"Removed {removed_count} additional expert_summary fields during parsing")
        
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
            
        return True, len(data)
        
    except json.JSONDecodeError as e:
        print(f"JSON parsing error: {e}")
        print(f"Error position: line {e.lineno}, column {e.colno}")
        
        # Try to identify the problematic area
        lines = cleaned_content.split('\n')
        if hasattr(e, 'lineno') and e.lineno <= len(lines):
            print(f"Problematic line: {lines[e.lineno - 1]}")
        
        # Save the intermediate result for inspection
        intermediate_file = output_file + ".intermediate"
        with open(intermediate_file, 'w', encoding='utf-8') as f:
            f.write(cleaned_content)
        
        print(f"Intermediate result saved to: {intermediate_file}")
        return False, 0

if __name__ == "__main__":
    input_file = "/Users/reidsterling/Desktop/Synagamy/Synagamy3.0/Data/JSON/Education_Topics.json"
    output_file = "/Users/reidsterling/Desktop/Synagamy/Synagamy3.0/Data/JSON/Education_Topics.json"
    
    # Create a backup first
    backup_file = input_file + ".backup"
    print(f"Creating backup at: {backup_file}")
    
    try:
        with open(input_file, 'r', encoding='utf-8') as src, open(backup_file, 'w', encoding='utf-8') as dst:
            dst.write(src.read())
        print("Backup created successfully")
    except Exception as e:
        print(f"Error creating backup: {e}")
        exit(1)
    
    # Clean the file
    success, entry_count = clean_json_file(input_file, output_file)
    
    if success:
        print(f"\n✓ Operation completed successfully!")
        print(f"✓ Processed {entry_count} entries")
        print(f"✓ Backup saved as: {backup_file}")
    else:
        print(f"\n⚠ Operation completed with errors")
        print(f"✓ Backup saved as: {backup_file}")
        print("Please check the intermediate file for issues")