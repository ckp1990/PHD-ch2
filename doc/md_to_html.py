import re
import sys
import os

def parse_markdown(md_content):
    html_lines = []
    html_lines.append("<html><body>")
    
    in_list = False
    list_type = None # 'ul' or 'ol'
    
    lines = md_content.split('\n')
    
    for line in lines:
        stripped_line = line.strip()
        
        # Handle Lists
        is_ul = stripped_line.startswith('- ') or stripped_line.startswith('* ')
        is_ol = re.match(r'^\d+\.', stripped_line)
        
        if is_ul or is_ol:
            current_list_type = 'ul' if is_ul else 'ol'
            
            if not in_list:
                html_lines.append(f"<{current_list_type}>")
                in_list = True
                list_type = current_list_type
            elif list_type != current_list_type:
                # Close previous list and open new one (nested lists not fully supported in this simple version, but switching types is)
                html_lines.append(f"</{list_type}>")
                html_lines.append(f"<{current_list_type}>")
                list_type = current_list_type
                
            # Process list item content
            if is_ul:
                content = stripped_line[2:]
            else:
                content = re.sub(r'^\d+\.\s*', '', stripped_line)
            
            content = parse_inline(content)
            html_lines.append(f"<li>{content}</li>")
            continue
            
        else:
            if in_list:
                html_lines.append(f"</{list_type}>")
                in_list = False
                list_type = None

        if not stripped_line:
            continue
            
        # Headers
        if stripped_line.startswith('#'):
            level = len(stripped_line.split(' ')[0])
            content = stripped_line[level+1:].strip()
            content = parse_inline(content)
            html_lines.append(f"<h{level}>{content}</h{level}>")
            continue
            
        # Horizontal Rule
        if stripped_line.startswith('---'):
            html_lines.append("<hr>")
            continue
            
        # Paragraphs
        content = parse_inline(stripped_line)
        html_lines.append(f"<p>{content}</p>")
        
    if in_list:
        html_lines.append(f"</{list_type}>")
        
    html_lines.append("</body></html>")
    return '\n'.join(html_lines)

def parse_inline(text):
    # Bold
    text = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', text)
    # Italic
    text = re.sub(r'\*(.*?)\*', r'<i>\1</i>', text)
    # Code
    text = re.sub(r'`(.*?)`', r'<code>\1</code>', text)
    # Link
    text = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', text)
    return text

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python md_to_html.py <input_md> <output_html>")
        sys.exit(1)
        
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
            
        html_content = parse_markdown(md_content)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
            
        print(f"Successfully converted {input_path} to {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
