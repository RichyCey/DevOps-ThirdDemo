# -*- coding: utf-8 -*-

from django.utils import timezone

from django.db import models
from django.urls import reverse


class Category(models.Model):
    category = models.CharField(u'Categories',
       max_length=250, help_text=u'Max 250 symb.')
    slug = models.SlugField(u'Slug')
    objects = models.Manager()

    class Meta:
        verbose_name = u'Categories'
        verbose_name_plural = u'Categories'

    def __str__(self):
        return self.category

    def get_absolute_url(self):
        try:
            url = reverse('articles-category-list',
                          kwargs={'slug': self.slug})
        except:
            url = "/"
        return url



class Article(models.Model):
    title = models.CharField(u'Title', max_length=250,
                             help_text=u'Max 250 symb.')
    description = models.TextField(blank=True,
                                   verbose_name=u'Description')
    pub_date = models.DateTimeField(u'Data',
                                    default=timezone.now)
    slug = models.SlugField(u'Slug',
                            unique_for_date='pub_date')

    main_page = models.BooleanField(u'Main',
                                    default=False,
                                    help_text=u'Show')
    category = models.ForeignKey(Category,
                                 related_name='news',
                                 blank=True,
                                 null=True,
                                 verbose_name=u'Category',
                                 on_delete=models.CASCADE)
    objects = models.Manager()

    class Meta:
        ordering = ['-pub_date']
        verbose_name = u'Publication'
        verbose_name_plural = u'Publications'

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        try:
            url = reverse('news-detail',
                          kwargs={
                              'year': self.pub_date.strftime("%Y"),
                              'month': self.pub_date.strftime("%m"),
                              'day': self.pub_date.strftime("%d"),
                              'slug': self.slug,
                          })
        except:
            url = "/"
        return url


class ArticleImage(models.Model):
    article = models.ForeignKey(Article,
                                verbose_name=u'Publication',
                                related_name='images',
                                on_delete=models.CASCADE)
    image = models.ImageField(u'Photo', upload_to='photos')
    title = models.CharField(u'Title', max_length=250,
                             help_text=u'Max 250 symb.',
                             blank=True)

    class Meta:
        verbose_name = u'Photo for publication'
        verbose_name_plural = u'Photo for publication'

    def __str__(self):
        return self.title

    @property
    def filename(self):
        return self.image.name.rsplit('/', 1)[-1]
