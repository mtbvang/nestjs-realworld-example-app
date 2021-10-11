import {Test, TestingModule} from '@nestjs/testing';
import { TagController } from './tag.controller';
import { TagService } from './tag.service';
import {TypeOrmModule} from "@nestjs/typeorm";
import {TagEntity} from "./tag.entity";
import {ConfigModule} from "@nestjs/config";

describe('TagController', () => {
  let tagController: TagController;
  let tagService: TagService;
  let module: TestingModule;

  beforeEach(async () => {
    module = await Test.createTestingModule({
      imports: [TypeOrmModule.forRoot(), ConfigModule.forRoot({
        isGlobal: true,
      }), TypeOrmModule.forFeature([TagEntity])],
      controllers: [TagController],
      providers: [TagService],
    }).compile();

    tagService = module.get<TagService>(TagService);
    tagController = module.get<TagController>(TagController);
  });

  afterEach(async () => {
    await module.close();
  });

  describe('findAll', () => {
    it('should return an array of tags', async () => {
      const tags : TagEntity[] = [];
      const createTag = (id, name) => {
        const tag = new TagEntity();
        tag.id = id;
        tag.tag = name;
        return tag;
      }
      tags.push(createTag(1, 'angularjs'));
      tags.push(createTag(2, 'reactjs'));

      jest.spyOn(tagService, 'findAll').mockImplementation(() => Promise.resolve(tags));
      
      const findAllResult = await tagController.findAll();
      expect(findAllResult).toBe(tags);
    });
  });
});