```python
r'{}-{}'.format(datetime.utcnow().strftime('%Y.%m.%d__%Hh%Mm%Ss.%f')[:-3], uuid.uuid4().hex[:8])
```