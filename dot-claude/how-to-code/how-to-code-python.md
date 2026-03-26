# How to Write Python Code Following Style Conventions

1. **Import library aliases consistently for frequently-used subclasses**. Use `import pydantic as pdt` and `import typing as tp` for libraries where you reference many subclasses (like `pdt.BaseModel`, `pdt.Field`, `tp.Optional`, `tp.Union`), then reference all subclasses and functions through these aliases.

2. **Add trailing commas in function definitions with 2+ parameters**. Place a comma after the last parameter to enable automatic line breaking by formatters like black.

3. **Use explicit parameter names in function calls**. Always specify parameter names when calling functions instead of relying on positional arguments (e.g., `func(name=value)` not `func(value)`).

4. **Type hint all function parameters and return values**. Include type annotations using the `tp` alias for all function signatures to improve code clarity and enable static type checking.

5. **Use `textwrap.dedent` for multi-line strings in indented code**. Wrap multi-line strings with `textwrap.dedent()` to remove common leading whitespace while maintaining code readability. For performance-critical loops with many iterations and a fixed template structure, define the dedented string once outside the loop and reuse it with string formatting.

6. **Run black formatter after code changes**. Execute `black <filename>.py` to ensure consistent code formatting across the project.

## Example:

```python
# RULE 1: Import library aliases for frequently-used subclasses
import pydantic as pdt
import typing as tp
from datetime import datetime
import textwrap

# RULE 1: Reference all pydantic and typing subclasses through aliases
class UserProfile(pdt.BaseModel):
    username: str
    email: str
    age: tp.Optional[int] = None
    tags: tp.List[str] = pdt.Field(default_factory=list)

    @pdt.validator('email')
    def validate_email(cls, v: str) -> str:
        if '@' not in v:
            raise ValueError('Invalid email')
        return v

class MessageData(pdt.BaseModel):
    content: str
    timestamp: datetime
    metadata: tp.Dict[str, tp.Any] = {}

# RULE 1: Use aliases for all typing constructs
def process_data(
    items: tp.List[tp.Dict[str, tp.Any]],
    callback: tp.Optional[tp.Callable[[str], None]] = None,
) -> tp.Union[str, int]:
    pass

# RULE 2: Add trailing commas in function definitions with 2+ parameters
def create_user(
    username: str,
    email: str,
    age: tp.Optional[int],
) -> UserProfile:
    return UserProfile(username=username, email=email, age=age)

# RULE 2: Trailing comma enables black to format parameters vertically
def retrieve_message(
    storage_base: str,
    project_id: str,
    user_id: str,
    include_metadata: bool,
) -> tp.Optional[MessageData]:
    pass

def update_user_profile(
    user_id: str,
    username: tp.Optional[str] = None,
    email: tp.Optional[str] = None,
    age: tp.Optional[int] = None,
    tags: tp.Optional[tp.List[str]] = None,
) -> UserProfile:
    pass

# RULE 3: Use explicit parameter names in function calls
user = create_user(
    username='john_doe',
    email='john@example.com',
    age=25,
)

# RULE 3: Explicit parameters make code self-documenting
message = retrieve_message(
    storage_base='/data/storage',
    project_id='proj_123',
    user_id='user_456',
    include_metadata=True,
)

# RULE 3: Even for simple calls, use parameter names
def send_notification(user_id: str, message: str) -> bool:
    return True

result = send_notification(user_id='user_123', message='Hello!')

# RULE 4: Type hint all function parameters and return values
def process_tags(
    tags: tp.List[str],
    filter_empty: bool,
) -> tp.List[str]:
    if filter_empty:
        return [tag for tag in tags if tag.strip()]
    return tags

# RULE 4: Use tp.Optional for nullable returns
def find_user_by_id(user_id: str) -> tp.Optional[UserProfile]:
    # Search logic here
    return None

# RULE 4: Use tp.Union for multiple possible return types
def get_config_value(key: str) -> tp.Union[str, int, bool]:
    config = {'debug': True, 'port': 8080, 'host': 'localhost'}
    return config.get(key, '')

# RULE 4: Complex type hints with nested structures
def transform_data(
    data: tp.Dict[str, tp.List[tp.Dict[str, tp.Any]]],
) -> tp.List[tp.Tuple[str, int]]:
    return [(k, len(v)) for k, v in data.items()]

# RULE 5: Use textwrap.dedent for multi-line strings in indented code
def create_cli_parser() -> None:
    import argparse

    parser = argparse.ArgumentParser(
        epilog=textwrap.dedent("""
            Examples:
                python script.py --input file.txt
                python script.py --verbose
        """),
    )
    return parser

# RULE 5: For large loops with fixed template, extract outside loop
def generate_reports(items: tp.List[tp.Dict[str, tp.Any]]) -> tp.List[str]:
    template = textwrap.dedent("""
        Report: {name}
        Status: {status}
    """).strip()

    return [template.format(name=x['name'], status=x['status']) for x in items]

# RULE 6: Run black formatter after code changes
# Command: black this_file.py
# This ensures consistent spacing, line breaks, and formatting
# Black will automatically format the code according to PEP 8 standards
```