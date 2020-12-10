import setuptools
from pathlib import Path


with (Path(__file__).absolute().parent.parent / 'VERSION').open() as f:
    VERSION = f.read().strip()


setuptools.setup(
    name='geonature',
    description='Application de saisie et de synthèse des observations faune et flore',
    python_requires='>=3.6',
    version=VERSION,
    classifiers=[
        "Framework :: Flask",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
    ],
    entry_points={
        'console_scripts': [
            'geonature = geonature.core.command:main',
        ],
    },
)
